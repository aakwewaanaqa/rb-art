module RbArt
  def self.f_step_t f, step, t
    (f..t).step(step).to_a
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
    when Float
      f
    when Integer
      f.to_f
    when NilClass
      raise ArgumentError, "param not set"
    end
  end
end