module RbArt
  def self.f_step_t f, step, t
    (f..t).step(step).to_a
  end

  # 把 unpack_param! 認得的型別（Range / ArithmeticSequence / Array / 純值）轉成
  # 人看得懂的字串，用來把「這次生成用了什麼參數」匯出給別人看——只是描述設定
  # 本身，不會像 unpack_param! 一樣真的去 sample 出一個值。
  def self.describe_param(f)
    case f
    when Enumerator::ArithmeticSequence
      step = f.step
      "#{f.begin}..#{f.end}#{step == 1 ? "" : " step #{step}"}"
    else
      f.to_s
    end
  end

  def self.unpack_param!(f, count = 1)
    case f
    when Enumerator::ArithmeticSequence
      return f.to_a.sample if count == 1
      f.to_a.sample count
    when Range
      return f.to_a.sample if count == 1
      f.to_a.sample count
    when Array
      return f.to_a.sample if count == 1
      f.sample count
    when NilClass
      raise ArgumentError, "param not set"
    else
      f
    end
  end

  TwoPi = Math::PI * 2

  # 三次平滑步（smoothstep），把線性的 t（0..1）重新映射成頭尾趨緩、
  # 中段加速的時間緩動曲線：f'(0) = f'(1) = 0。
  def self.ease_in_out(t)
    t * t * (3 - 2 * t)
  end

  # 從一個 style hash 裡取出用到的濾鏡物件（例如 GlowFilter），給 Canvas#draw
  # 用來登記 <defs>。style[:filter] 沒給、或給的是純字串（直接寫 "url(#id)"）
  # 就回傳空陣列——只有濾鏡物件（回應 to_def）才需要 Canvas 額外登記定義。
  def self.style_filters(style)
    f = style[:filter]
    f.respond_to?(:to_def) ? [f] : []
  end

  DefaultStyle = {
    fill: "none",
    stroke: "black",
    stroke_width: "1"
  }
end