require_relative "geometry"
require "tempfile"

# 最小的 SVG 文件組裝器：收集元素字串，輸出成一份 <svg>。
# 不依賴任何 gem，純字串拼接。
#
#   RbArt::Canvas.new {
#     width  200
#     height 200
#     svg "out/fern.svg"
#     draw RbArt::Path.new { ... }
#   }
module RbArt
  class Canvas
    include Geometry

    DIRECTIONS = {
      top_to_bottom: [0, 0, 0, 100],
      bottom_to_top: [0, 100, 0, 0],
      left_to_right: [0, 0, 100, 0],
      right_to_left: [100, 0, 0, 0],
      diagonal:      [0, 0, 100, 100],
    }.freeze

    # block 內可以設定 width / height / background / svg，也可以呼叫
    # draw 加元素，以及任何 Geometry 的 bare 方法/常數。
    # 若有設定 svg 路徑，block 跑完後會直接寫檔。
    def initialize(&block)
      @elements = []
      @defs = []
      @gradient_count = 0
      instance_eval(&block) if block
      write(@svg) if @svg
      write_png(@png) if @png
      write_png8(@png8[:path], colors: @png8[:colors]) if @png8
    end

    def width(value = nil) = value.nil? ? @width : (@width = value)
    def height(value = nil) = value.nil? ? @height : (@height = value)
    def background(value = nil) = value.nil? ? @background : (@background = value)
    def svg(value = nil) = value.nil? ? @svg : (@svg = value)
    def png(value = nil) = value.nil? ? @png : (@png = value)

    # 輸出調色盤模式（indexed）PNG，色彩數少的畫面（例如純色填色的向量圖）
    # 檔案可以小非常多。colors 預設 256，可視需要調低。
    def png8(value = nil, colors: 256)
      return @png8 if value.nil?

      @png8 = { path: value, colors: colors }
    end

    # element 可以是 SVG 字串，也可以是任何有 to_svg 的物件（例如 RbArt::Path.new { ... }）。
    def draw(element)
      @elements << (element.respond_to?(:to_svg) ? element.to_svg : element)
      self
    end

    # 定義一個線性漸層，回傳可以直接丟給 fill / stroke 的 "url(#id)" 字串。
    #
    #   grad = canvas.linear_gradient(stops: ["#1B1F3B", "#6C3AC7"])
    #   grad = canvas.linear_gradient(direction: :left_to_right, stops: { 0 => "#fff", 50 => "#f00", 100 => "#000" })
    #   grad = canvas.linear_gradient(direction: [0, 0, 100, 50], stops: [...]) # 自訂 x1,y1,x2,y2（百分比）
    def linear_gradient(id: nil, direction: :top_to_bottom, stops:)
      id ||= next_gradient_id
      x1, y1, x2, y2 = DIRECTIONS.fetch(direction) { direction }
      @defs << <<~SVG.strip
        <linearGradient id="#{id}" x1="#{x1}%" y1="#{y1}%" x2="#{x2}%" y2="#{y2}%">
        #{stop_tags(stops)}
        </linearGradient>
      SVG
      "url(##{id})"
    end

    # 定義一個放射狀漸層，回傳可以直接丟給 fill / stroke 的 "url(#id)" 字串。
    #
    #   grad = canvas.radial_gradient(stops: ["#fff", "#000"])
    def radial_gradient(id: nil, stops:, cx: 50, cy: 50, r: 50)
      id ||= next_gradient_id
      @defs << <<~SVG.strip
        <radialGradient id="#{id}" cx="#{cx}%" cy="#{cy}%" r="#{r}%">
        #{stop_tags(stops)}
        </radialGradient>
      SVG
      "url(##{id})"
    end

    def to_svg
      body = @elements.join("\n")
      bg = @background ? %(<rect width="100%" height="100%" fill="#{@background}"/>\n) : ""
      defs = @defs.empty? ? "" : "<defs>\n#{@defs.join("\n")}\n</defs>\n"
      <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" width="#{@width}" height="#{@height}" viewBox="0 0 #{@width} #{@height}">
        #{defs}#{bg}#{body}
        </svg>
      SVG
    end

    def write(path)
      File.write(path, to_svg)
      path
    end

    # 靠系統的 rsvg-convert 把組好的 SVG 轉成 PNG（macOS: `brew install librsvg`）。
    def write_png(path)
      Tempfile.create(["rb_art", ".svg"]) { |f|
        f.write(to_svg)
        f.flush
        unless system("rsvg-convert", "-o", path, f.path)
          raise "轉出 PNG 失敗，請確認已安裝 rsvg-convert（brew install librsvg）"
        end
      }
      path
    end

    # 先轉出全彩 PNG 到暫存檔，再用 ImageMagick 壓成 colors 色的調色盤 PNG8。
    def write_png8(path, colors:)
      Tempfile.create(["rb_art", ".png"]) { |f|
        write_png(f.path)
        unless system("magick", f.path, "-colors", colors.to_s, "PNG8:#{path}")
          raise "轉出 PNG8 失敗，請確認已安裝 ImageMagick（brew install imagemagick）"
        end
      }
      path
    end

    private

    def next_gradient_id
      @gradient_count += 1
      "gradient#{@gradient_count}"
    end

    # stops 可以傳：
    #   - 陣列（顏色平均分配 offset）：["#fff", "#f00", "#000"]
    #   - Hash（自訂 offset）：{ 0 => "#fff", 30 => "#f00", 100 => "#000" }
    def stop_tags(stops)
      pairs =
        if stops.is_a?(Hash)
          stops.to_a
        else
          n = stops.length
          stops.each_with_index.map { |color, i| [n == 1 ? 0 : (100.0 * i / (n - 1)).round(2), color] }
        end
      pairs.map { |offset, color| %(  <stop offset="#{offset}%" stop-color="#{color}"/>) }.join("\n")
    end
  end
end
