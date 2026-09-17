require_relative "geometry"

module RbArt
  # 組出 SVG path 的 `d` 屬性字串的小型 DSL。
  # 每個方法對應一個 path 指令，大寫方法為絕對座標，
  # 方法名加上 `!` 為對應的小寫（相對座標）版本。
  #
  #   d = RbArt::Path.build do
  #     m 10, 10
  #     l 90, 10
  #     l 50, 90
  #     z
  #   end
  #   #=> "M 10 10 L 90 10 L 50 90 Z"
  class Path
    include Geometry

    # 只組出 `d` 字串（座標指令）。
    def self.build(&block)
      new(&block).to_d
    end

    # 組出完整 `<path>` 標籤，block 內除了座標指令，
    # 還可以呼叫 fill / stroke / stroke_width / attr 設定樣式。
    def self.draw(&block)
      new(&block).to_svg
    end

    def initialize(&block)
      @commands = []
      @attrs = {}
      instance_eval(&block) if block_given?
    end

    # -- 樣式屬性 --
    def fill(color)         = (@attrs["fill"] = color)
    def stroke(color)       = (@attrs["stroke"] = color)
    def stroke_width(width) = (@attrs["stroke-width"] = width)
    def attr(name, value)   = (@attrs[name.to_s] = value)

    # 一次套用 { fill:, stroke:, stroke_width: } 這種樣式 hash，等同分別呼叫
    # fill / stroke / stroke_width，缺的 key 就跳過。
    def style(hash)
      fill hash[:fill] if hash.key?(:fill)
      stroke hash[:stroke] if hash.key?(:stroke)
      stroke_width hash[:stroke_width] if hash.key?(:stroke_width)
    end

    # -- 絕對座標 --
    # 每個座標都可以傳 Geometry::Point，或拆開傳 x, y 兩個數字，兩種可混用。
    def m(*args) = (x, y = coords(args); raw("M", pt(x, y)))
    def l(*args) = (x, y = coords(args); raw("L", pt(x, y)))
    def h(x)     = raw("H", fmt(x))
    def v(y)     = raw("V", fmt(y))
    def c(*args)
      x1, y1, x2, y2, x, y = coords(args)
      raw("C", "#{pt(x1, y1)}, #{pt(x2, y2)}, #{pt(x, y)}")
    end
    def s(*args)
      x2, y2, x, y = coords(args)
      raw("S", "#{pt(x2, y2)}, #{pt(x, y)}")
    end
    def q(*args)
      x1, y1, x, y = coords(args)
      raw("Q", "#{pt(x1, y1)}, #{pt(x, y)}")
    end
    def t(*args) = (x, y = coords(args); raw("T", pt(x, y)))
    def a(rx, ry, x_rotation, large_arc, sweep, *point)
      x, y = coords(point)
      raw("A", "#{fmt(rx)} #{fmt(ry)} #{fmt(x_rotation)} #{large_arc ? 1 : 0} #{sweep ? 1 : 0} #{pt(x, y)}")
    end
    def z = raw("Z", nil)

    # -- 相對座標（小寫指令，方法名加 `!`）--
    def m!(*args) = (x, y = coords(args); raw("m", pt(x, y)))
    def l!(*args) = (x, y = coords(args); raw("l", pt(x, y)))
    def h!(dx)    = raw("h", fmt(dx))
    def v!(dy)    = raw("v", fmt(dy))
    def c!(*args)
      x1, y1, x2, y2, x, y = coords(args)
      raw("c", "#{pt(x1, y1)}, #{pt(x2, y2)}, #{pt(x, y)}")
    end
    def s!(*args)
      x2, y2, x, y = coords(args)
      raw("s", "#{pt(x2, y2)}, #{pt(x, y)}")
    end
    def q!(*args)
      x1, y1, x, y = coords(args)
      raw("q", "#{pt(x1, y1)}, #{pt(x, y)}")
    end
    def t!(*args) = (x, y = coords(args); raw("t", pt(x, y)))

    def to_d = @commands.join(" ")

    def to_svg
      attrs = { "d" => to_d }.merge(@attrs)
      attr_str = attrs.map { |k, v| %(#{k}="#{v}") }.join(" ")
      "<path #{attr_str}/>"
    end

    private

    # 把混合了 Geometry::Point 與純數字的參數列表，攤平成一串數字。
    # 例如 [Point(1,2), 3] -> [1, 2, 3]，[1, 2, 3, 4] -> [1, 2, 3, 4] 不變。
    def coords(args) = args.flat_map { |a| a.is_a?(Geometry::Point) ? [a.x, a.y] : [a] }

    def pt(x, y) = "#{fmt(x)} #{fmt(y)}"

    def fmt(n) = n.is_a?(Numeric) ? n.round(2) : n

    def raw(cmd, args)
      @commands << (args ? "#{cmd} #{args}" : cmd)
      self
    end
  end
end
