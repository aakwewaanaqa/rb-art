require_relative "geometry"

module RbArt
  # 組出 SVG `<text>` 標籤的小型 DSL，跟 Path 同一套風格。
  #
  #   text = RbArt::Text.new {
  #     x 20
  #     y 40
  #     text "Hello"
  #     font_size 24
  #     fill "#fff"
  #   }
  #   text.to_svg #=> '<text x="20" y="40" font-size="24" fill="#fff">Hello</text>'
  #
  # `text` 內容含 "\n" 時會拆成多行，用 <tspan dy="1.2em"> 疊行（沿用同一個 x）。
  class Text
    include Geometry

    def initialize(&block)
      @x = 0
      @y = 0
      @attrs = {}
      instance_eval(&block) if block_given?
    end

    # 位置也可以傳 Geometry::Point：at Point.new(20, 40)
    def at(*args)
      x, y = args.first.is_a?(Geometry::Point) ? [args.first.x, args.first.y] : args
      x x
      y y
    end

    def x(value = nil) = value.nil? ? @x : (@x = value)
    def y(value = nil) = value.nil? ? @y : (@y = value)
    def text(value = nil) = value.nil? ? @text : (@text = value)

    def font_family(value = nil)   = value.nil? ? @attrs["font-family"] : (@attrs["font-family"] = value)
    def font_size(value = nil)     = value.nil? ? @attrs["font-size"] : (@attrs["font-size"] = value)
    def font_weight(value = nil)   = value.nil? ? @attrs["font-weight"] : (@attrs["font-weight"] = value)
    def fill(value = nil)          = value.nil? ? @attrs["fill"] : (@attrs["fill"] = value)
    def stroke(value = nil)        = value.nil? ? @attrs["stroke"] : (@attrs["stroke"] = value)
    def stroke_width(value = nil)  = value.nil? ? @attrs["stroke-width"] : (@attrs["stroke-width"] = value)
    def opacity(value = nil)       = value.nil? ? @attrs["opacity"] : (@attrs["opacity"] = value)
    def text_anchor(value = nil)   = value.nil? ? @attrs["text-anchor"] : (@attrs["text-anchor"] = value)
    def dominant_baseline(value = nil) = value.nil? ? @attrs["dominant-baseline"] : (@attrs["dominant-baseline"] = value)
    def attr(name, value)          = (@attrs[name.to_s] = value)

    # 一次套用 { fill:, stroke:, font_size: ... } 這種樣式 hash，缺的 key 就跳過。
    def style(hash)
      hash.each { |key, value| send(key, value) if respond_to?(key) }
    end

    def to_svg
      attr_str = { "x" => fmt(@x), "y" => fmt(@y) }.merge(@attrs)
        .map { |k, v| %(#{k}="#{v}") }.join(" ")
      "<text #{attr_str}>#{body}</text>"
    end

    private

    def body
      lines = (@text || "").to_s.split("\n", -1)
      return escape(lines.first || "") if lines.size <= 1

      lines.each_with_index.map { |line, i|
        i.zero? ? escape(line) : %(<tspan x="#{fmt(@x)}" dy="1.2em">#{escape(line)}</tspan>)
      }.join
    end

    def escape(str) = str.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")

    def fmt(n) = n.is_a?(Numeric) ? n.round(2) : n
  end
end
