class Integer
  def to_rad() Math::PI * self end
  def is_odd?() self % 2 == 1 end
  def lerp(v, t) self + (v - self) * t end
  def dist(v) (self - v).abs end
end

class Float
  def to_rad() Math::PI * self end
  def lerp(v, t) self + (v - self) * t end
  def dist(v) (self - v).abs end
end

class Array
  def second() self[1] end
  def third() self[2] end
  def scramble() self.sample count end
  def round_indexer(idx) self[idx % count] end
  def to_point() 
    RbArt::Geometry::Point.new(
      self.dig(0), 
      self.dig(1)
    )
  end

  def each_i_first_last(&block)
    n = count
    each_with_index { |v, idx|
      block&.call v, idx, idx.zero?, idx == n - 1
    }
  end
end