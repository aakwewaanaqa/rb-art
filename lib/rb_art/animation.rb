require "fileutils"

module RbArt
  # 把一系列 RbArt::Canvas frame 轉成 GIF / MP4。
  #
  # 依賴外部指令：`magick`（SVG -> PNG）與 `ffmpeg`（PNG 序列 -> GIF/MP4）。
  #
  #   RbArt::Animation.new {
  #     frames 60
  #     gif "out/animation.gif"
  #     mp4 "out/animation.mp4"
  #   }.render { |i, total|
  #     canvas = RbArt::Canvas.new(width: 200, height: 200, background: "#9ED06D")
  #     canvas << RbArt::Path.draw { ... }
  #     canvas
  #   }
  #
  # 搭配 Timeline 時可以不寫 render block，frames / fps / 每格內容都交給
  # Timeline 決定：
  #
  #   RbArt::Animation.new {
  #     timeline timeline
  #     canvas { width 200; height 200; background "#9ED06D" }
  #     gif "out/animation.gif"
  #   }.render
  #
  # render 結束時會自動輸出有設定的 gif / mp4（跟 Canvas 一樣：內容準備好就自動寫檔）。
  # 若只想拿到 frame 序列而不自動輸出，設定區塊不要呼叫 gif / mp4，事後再手動呼叫
  # write_gif / write_mp4 即可。
  #
  # canvas 座標可以照方便計算的小尺寸來畫（例如 200x200），輸出時用 scale:
  # 放大，因為 SVG 是向量，rasterize 時才放大是用目標解析度重新算線條，
  # 不是拿小圖直接縮放，所以不會糊。
  #
  #   RbArt::Animation.new { frames 60; scale 4 }.render { |i, total| ... }
  class Animation
    class ToolMissing < StandardError; end

    def initialize(&block)
      @dir = "out/frames"
      @scale = 1
      @fps = 24
      instance_eval(&block) if block
      # 給了 timeline 就以它為準：fps 跟 frames 都從它身上拿。
      # 不這樣做的話 fps 會有兩個來源，一旦不一致（timeline 用 12fps 取樣、
      # ffmpeg 用 24fps 編碼）動畫就會快兩倍，而且不會報錯。
      if @timeline
        @fps    = @timeline.fps
        @frames = @timeline.frame_count
      end
      @digits = @frames.to_s.length.clamp(3, Float::INFINITY).to_i
    end

    def frames(value = nil) = value.nil? ? @frames : (@frames = value)
    def dir(value = nil) = value.nil? ? @dir : (@dir = value)
    def scale(value = nil) = value.nil? ? @scale : (@scale = value)
    def gif(value = nil) = value.nil? ? @gif : (@gif = value)
    def mp4(value = nil) = value.nil? ? @mp4 : (@mp4 = value)
    def fps(value = nil) = value.nil? ? @fps : (@fps = value)

    # 吃一份 RbArt::Timeline，frames 跟 fps 都不用自己設（設了也會被覆蓋）。
    def timeline(value = nil) = value.nil? ? @timeline : (@timeline = value)

    # 設定每一格 Canvas 的固定部分（width / height / background 等）。
    # 跟 Canvas.new 的設定區塊寫法一樣，只是不含每格會變的內容——那部分
    # 交給 timeline 的 cue 負責。只有搭配 timeline、不自己寫 render block
    # 時才會用到。
    def canvas(&block) = block.nil? ? @canvas : (@canvas = block)

    # 有給 block：跟以前一樣，block 會被呼叫 frames 次，帶入
    # (frame_index, total_frames)，必須回傳一個 RbArt::Canvas。
    #
    # 沒給 block：改用 timeline 自動組——每一格新建一個 Canvas，套用
    # canvas 設定，再把 timeline.draw_at_frame(i) 要畫的東西逐一 draw 上去。
    # 這條路線要求 timeline 跟 canvas 都已經設定好。
    def render(&block)
      block ||= default_render_block
      # 先清掉整個 @dir 再重建，不能只 mkdir_p：write_gif / write_mp4 餵給
      # ffmpeg 的 png_glob 是 "frame_%03d.png" 這種序列號 pattern，ffmpeg 的
      # image2 demuxer 會從 0 開始連續讀到第一個缺號才停——如果上一次渲染
      # frame 數比這次多，殘留的舊檔案（例如上次 60 格、這次 42 格留下的
      # frame_042.png ~ frame_059.png）編號是連續的，會被 ffmpeg 誤判成這次
      # 動畫的延伸，接在新內容後面一起轉出去。
      FileUtils.rm_rf(@dir)
      FileUtils.mkdir_p(@dir)
      @frames.times do |i|
        canvas = block.call(i, @frames)
        canvas.write(svg_path(i))
      end
      write_gif if @gif
      write_mp4 if @mp4
      self
    end

    def write_gif(path = @gif, fps: @fps)
      raise ArgumentError, "缺少輸出路徑：請在設定區塊呼叫 gif \"...\"，或呼叫 write_gif 時指定 path" unless path

      rasterize!
      require_tool!("ffmpeg")
      palette = File.join(@dir, "palette.png")
      run!("ffmpeg -y -framerate #{fps} -i #{png_glob} -vf palettegen #{sh(palette)} -hide_banner -loglevel error")
      run!("ffmpeg -y -framerate #{fps} -i #{png_glob} -i #{sh(palette)} -lavfi paletteuse #{sh(path)} -hide_banner -loglevel error")
      path
    end

    def write_mp4(path = @mp4, fps: @fps)
      raise ArgumentError, "缺少輸出路徑：請在設定區塊呼叫 mp4 \"...\"，或呼叫 write_mp4 時指定 path" unless path

      rasterize!
      require_tool!("ffmpeg")
      run!("ffmpeg -y -framerate #{fps} -i #{png_glob} -c:v libx264 -pix_fmt yuv420p -movflags +faststart #{sh(path)} -hide_banner -loglevel error")
      path
    end

    private

    def default_render_block
      raise ArgumentError, "render 沒給 block 時需要先設定 timeline" unless @timeline
      raise ArgumentError, "render 沒給 block 時需要先設定 canvas { width ...; height ... }" unless @canvas

      canvas_config = @canvas
      timeline      = @timeline
      -> (i, _total) {
        Canvas.new {
          instance_eval(&canvas_config)
          timeline.draw_at_frame(i).each { |element| draw element }
        }
      }
    end

    def svg_path(i) = File.join(@dir, "frame_%0#{@digits}d.svg" % i)
    def png_path(i) = File.join(@dir, "frame_%0#{@digits}d.png" % i)
    def png_glob = File.join(@dir, "frame_%0#{@digits}d.png")

    # SVG -> 8-bit PNG。16-bit PNG 會讓 ffmpeg 的 palettegen filter 出錯，故強制降到 8-bit。
    #
    # 優先用 rsvg-convert：ImageMagick 內建的 SVG rasterizer（MSVG）幾乎不畫 stroke，
    # 會讓有 stroke 的 path 在轉出的 PNG/GIF/MP4 裡整條線消失。
    def rasterize!
      tool = has_tool?("rsvg-convert") ? :rsvg : :magick
      warn "警告：找不到 rsvg-convert，改用 magick 轉檔，有 stroke 的圖形可能會畫不出來（建議 `brew install librsvg`）" if tool == :magick
      require_tool!("magick") if tool == :magick

      @frames.times do |i|
        cmd = if tool == :rsvg
          "rsvg-convert --zoom #{@scale} #{sh(svg_path(i))} -o #{sh(png_path(i))}"
        else
          "magick -density #{96 * @scale} #{sh(svg_path(i))} -depth 8 #{sh(png_path(i))}"
        end
        run!(cmd)
      end
    end

    def has_tool?(name) = system("which #{name} > /dev/null 2>&1")

    def require_tool!(name)
      return if has_tool?(name)

      raise ToolMissing, "找不到指令 `#{name}`，請先安裝（例如 `brew install #{name == "magick" ? "imagemagick" : name}`）"
    end

    def run!(cmd)
      system(cmd) || raise("command failed: #{cmd}")
    end

    def sh(path) = "'#{path}'"
  end
end
