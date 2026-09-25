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
end