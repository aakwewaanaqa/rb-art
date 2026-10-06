module RbArt
  # 一個可調色的顏色物件，預設是全透明黑 #00000000。
  # 底層以 HSV(A) 為主要狀態；用 r/g/b 讀寫時會即時和 HSV 互相換算，
  # 這樣不管先用哪種方式、分幾次呼叫，都不會互相洗掉彼此的資訊。
  # 呼叫時不帶參數是 getter，帶參數是 setter。to_s 輸出 "#rrggbbaa"，
  # 可以直接當 fill / stroke 的值用。
  #
  #   color = RbArt::ColorHex.new {
  #     h 200
  #     s 0.8
  #     v 0.9
  #     a 255
  #   }
  #   color.to_s #=> "#39c3e6ff"
  #
  #   color = RbArt::ColorHex.new { code "#9ED06D" }
  #   color.h 200 # 直接轉色相，s/v 維持不變
  class ColorHex
    def initialize(&block)
      @h = 0.0
      @s = 0.0
      @v = 0.0
      @a = 0
      instance_eval(&block) if block
    end

    def h(value = nil) = value.nil? ? @h : (@h = value % 360)
    def s(value = nil) = value.nil? ? @s : (@s = value.clamp(0.0, 1.0))
    def v(value = nil) = value.nil? ? @v : (@v = value.clamp(0.0, 1.0))
    def a(value = nil) = value.nil? ? @a : (@a = value.clamp(0, 255))

    def r(value = nil) = value.nil? ? rgb[0] : set_rgb(r: value, g: rgb[1], b: rgb[2])
    def g(value = nil) = value.nil? ? rgb[1] : set_rgb(r: rgb[0], g: value, b: rgb[2])
    def b(value = nil) = value.nil? ? rgb[2] : set_rgb(r: rgb[0], g: rgb[1], b: value)

    # 讀取／設定完整 hex 色碼字串，支援 "#rgb" "#rgba" "#rrggbb" "#rrggbbaa"。
    def code(value = nil) = value.nil? ? to_s : set_hex(value)

    def to_s
      r, g, b = rgb
      "#%02x%02x%02x%02x" % [r, g, b, @a]
    end

    # 在 RGB(A) 空間內插出一個新的 ColorHex，t=0 回傳自己的顏色、t=1 回傳 other 的顏色。
    #
    #   a = RbArt::ColorHex.new { code "#ff0000" }
    #   b = RbArt::ColorHex.new { code "#0000ff" }
    #   a.lerp(b, 0.5).to_s #=> "#7f007fff"
    def lerp(other, t)
      t = t.clamp(0.0, 1.0)
      r1, g1, b1 = rgb
      r2, g2, b2 = other.rgb
      nr = (r1 + (r2 - r1) * t).round
      ng = (g1 + (g2 - g1) * t).round
      nb = (b1 + (b2 - b1) * t).round
      na = (@a + (other.a - @a) * t).round

      self.class.new {
        r nr
        g ng
        b nb
        a na
      }
    end

    def self.lerp(from, to, t) = from.lerp(to, t)

    # 兩個顏色在 RGB 空間的歐幾里得距離，數字越小代表視覺上越接近。
    #
    #   a.dist(b) #=> 0.0（同色）～ 441.67（黑對白，最大值）
    def dist(other)
      r1, g1, b1 = rgb
      r2, g2, b2 = other.rgb
      Math.sqrt((r1 - r2)**2 + (g1 - g2)**2 + (b1 - b2)**2)
    end

    protected

    # 依目前 @h/@s/@v 算出 [r, g, b]（0~255 整數）。
    def rgb
      c = @v * @s
      x = c * (1 - ((@h / 60.0) % 2 - 1).abs)
      m = @v - c

      r1, g1, b1 =
        case @h
        when 0...60   then [c, x, 0]
        when 60...120 then [x, c, 0]
        when 120...180 then [0, c, x]
        when 180...240 then [0, x, c]
        when 240...300 then [x, 0, c]
        else [c, 0, x]
        end

      [r1, g1, b1].map { |ch| ((ch + m) * 255).round }
    end

    # 給定 [r, g, b]（0~255）反推 @h/@s/@v。
    def set_rgb(r:, g:, b:)
      r = r.clamp(0, 255) / 255.0
      g = g.clamp(0, 255) / 255.0
      b = b.clamp(0, 255) / 255.0
      max = [r, g, b].max
      min = [r, g, b].min
      delta = max - min

      @h =
        if delta.zero?
          0.0
        elsif max == r
          60 * (((g - b) / delta) % 6)
        elsif max == g
          60 * (((b - r) / delta) + 2)
        else
          60 * (((r - g) / delta) + 4)
        end

      @s = max.zero? ? 0.0 : delta / max
      @v = max
    end

    def set_hex(str)
      hex = str.sub(/\A#/, "")
      hex = hex.chars.map { |ch| ch * 2 }.join if hex.length == 3 || hex.length == 4

      set_rgb(r: hex[0..1].to_i(16), g: hex[2..3].to_i(16), b: hex[4..5].to_i(16))
      @a = hex.length >= 8 ? hex[6..7].to_i(16) : 255
    end
  end
end
