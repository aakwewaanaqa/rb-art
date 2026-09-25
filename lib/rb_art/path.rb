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

    # 指令暫存的結構：cmd 是 SVG 指令字母、points 是這個指令帶的座標點
    # （Geometry::Point 陣列，沒有座標的指令如 Z 則是 nil）、extra 放
    # 不是座標的參數（H/V 的單軸數值、A 的 rx/ry/旋轉角/旗標）。
    # 拆成結構化資料而不是直接字串化，是為了將來能在 to_d 之前對
    # points 做一輪效果轉換（例如彎曲），呼叫端的介面不受影響。
    Command = Struct.new(:cmd, :points, :extra)

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
      @effects = []
      instance_eval(&block) if block_given?
    end

    # -- 樣式屬性 --
    def fill(color)         = (@attrs["fill"] = color)
    def stroke(color)       = (@attrs["stroke"] = color)
    def stroke_width(width) = (@attrs["stroke-width"] = width)
    def attr(name, value)   = (@attrs[name.to_s] = value)

    # 疊加一個 Point -> Point 的變形（例如彎曲），套用在 to_d 字串化之前。
    # 可以呼叫多次疊加，依呼叫順序套用；前一個 effect 的輸出就是下一個的輸入。
    def effect(fx = nil, &block)
      @effects << (fx || block)
      self
    end

    # 一次套用 { fill:, stroke:, stroke_width: } 這種樣式 hash，等同分別呼叫
    # fill / stroke / stroke_width，缺的 key 就跳過。
    def style(hash)
      fill hash[:fill] if hash.key?(:fill)
      stroke hash[:stroke] if hash.key?(:stroke)
      stroke_width hash[:stroke_width] if hash.key?(:stroke_width)
    end

    # -- 絕對座標 --
    # 每個座標都可以傳 Geometry::Point，或拆開傳 x, y 兩個數字，兩種可混用。
    def m(*args) = raw("M", points(args))
    def l(*args) = raw("L", points(args))
    def h(x)     = raw("H", nil, extra: [x])
    def v(y)     = raw("V", nil, extra: [y])
    def c(*args) = raw("C", points(args))
    def s(*args) = raw("S", points(args))
    def q(*args) = raw("Q", points(args))
    def t(*args) = raw("T", points(args))
    def a(rx, ry, x_rotation, large_arc, sweep, *point)
      raw("A", points(point), extra: [rx, ry, x_rotation, large_arc ? 1 : 0, sweep ? 1 : 0])
    end
    def z = raw("Z", nil)

    # 用 Catmull-Rom spline 平滑通過整串點畫一條曲線：m 到第一個點，
    # 接著把 CubicBezier.catmull_rom_chain 算出的每一段轉成 c 指令。
    # tension / closed 意義同 CubicBezier.catmull_rom_chain。
    def catmull_rom(pts, tension: 1.0, closed: false)
      m pts.first
      Geometry::CubicBezier.catmull_rom_chain(pts, tension: tension, closed: closed).each { |bez|
        c bez.p1, bez.p2, bez.p3
      }
      z if closed
    end

    # 把 beziers（中心線，可以是單一 CubicBezier、CubicBezier 陣列，或
    # ArbitraryChain）展開成有寬度的填色外框（Expand Stroke），直接用折線
    # 畫出來。width/closed/samples 等意義見 Geometry::StrokeExpand.outline。
    # closed: true 時會畫出「外圈 + 內圈」兩條封閉路徑，記得自己在
    # style/attr 設 fill-rule: evenodd 才會變成圈狀。
    def expand_stroke(beziers, width, closed: false, samples: 16, cap_samples: 8, join_samples: 6)
      loops = Geometry::StrokeExpand.outline(
        beziers, width, closed: closed, samples: samples, cap_samples: cap_samples, join_samples: join_samples
      )
      loops.each { |loop|
        m loop.first
        l(*loop[1..])
        z
      }
    end

    # -- 相對座標（小寫指令，方法名加 `!`）--
    def m!(*args) = raw("m", points(args))
    def l!(*args) = raw("l", points(args))
    def h!(dx)    = raw("h", nil, extra: [dx])
    def v!(dy)    = raw("v", nil, extra: [dy])
    def c!(*args) = raw("c", points(args))
    def s!(*args) = raw("s", points(args))
    def q!(*args) = raw("q", points(args))
    def t!(*args) = raw("t", points(args))

    def to_d = @commands.map { |command| render(apply_effects(command)) }.join(" ")

    def to_svg
      attrs = { "d" => to_d }.merge(@attrs)
      attr_str = attrs.map { |k, v| %(#{k}="#{v}") }.join(" ")
      "<path #{attr_str}/>"
    end

    private

    # 把混合了 Geometry::Point 與純數字的參數列表，攤平後兩兩一組包成
    # Geometry::Point。例如 [Point(1,2), 3, 4] -> [Point(1,2), Point(3,4)]。
    def points(args)
      nums = args.flat_map { |a| a.is_a?(Geometry::Point) ? [a.x, a.y] : [a] }
      nums.each_slice(2).map { |x, y| Geometry::Point.new(x, y) }
    end

    def raw(cmd, points, extra: nil)
      @commands << Command.new(cmd, points, extra)
      self
    end

    # 把 @effects 依序套用到一個指令的 points 上，回傳套用後的新 Command。
    # H/V 只帶單軸數值、Z 沒有座標，這兩種沒有 points 可套，原樣跳過。
    def apply_effects(command)
      return command if command.points.nil? || @effects.empty?

      transformed = command.points.map { |p| @effects.reduce(p) { |point, fx| fx.call(point) } }
      Command.new(command.cmd, transformed, command.extra)
    end

    # 指令真正字串化的地方，只在 to_d 被呼叫時才發生。
    def render(command)
      case command.cmd
      when "Z", "z"
        command.cmd
      when "H", "V", "h", "v"
        "#{command.cmd} #{fmt(command.extra[0])}"
      when "A", "a"
        rx, ry, x_rotation, large_arc, sweep = command.extra
        p = command.points.first
        "#{command.cmd} #{fmt(rx)} #{fmt(ry)} #{fmt(x_rotation)} #{large_arc} #{sweep} #{pt(p.x, p.y)}"
      else
        "#{command.cmd} #{command.points.map { |p| pt(p.x, p.y) }.join(", ")}"
      end
    end

    def pt(x, y) = "#{fmt(x)} #{fmt(y)}"

    def fmt(n) = n.is_a?(Numeric) ? n.round(2) : n
  end
end
