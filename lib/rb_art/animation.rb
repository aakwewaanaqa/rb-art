require "fileutils"

module RbArt
  # 把一系列 RbArt::Canvas frame 轉成 GIF / MP4。
  #
  # 依賴外部指令：`magick`（SVG -> PNG）與 `ffmpeg`（PNG 序列 -> GIF/MP4）。
  #
  #   animation = RbArt::Animation.new {
  #     frames 60
  #     gif "out/animation.gif"
  #     mp4 "out/animation.mp4"
  #   }.render { |i, total|
  #     canvas = RbArt::Canvas.new(width: 200, height: 200, background: "#9ED06D")
  #     canvas << RbArt::Path.draw { ... }
  #     canvas
  #   }
  #   animation.write_gif
  #   animation.write_mp4
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
      @digits = @frames.to_s.length.clamp(3, Float::INFINITY).to_i
    end

    def frames(value = nil) = value.nil? ? @frames : (@frames = value)
    def dir(value = nil) = value.nil? ? @dir : (@dir = value)
    def scale(value = nil) = value.nil? ? @scale : (@scale = value)
    def gif(value = nil) = value.nil? ? @gif : (@gif = value)
    def mp4(value = nil) = value.nil? ? @mp4 : (@mp4 = value)
    def fps(value = nil) = value.nil? ? @fps : (@fps = value)

    # block 會被呼叫 frames 次，帶入 (frame_index, total_frames)，
    # 必須回傳一個 RbArt::Canvas。
    def render(&block)
      FileUtils.mkdir_p(@dir)
      @frames.times do |i|
        canvas = block.call(i, @frames)
        canvas.write(svg_path(i))
      end
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
