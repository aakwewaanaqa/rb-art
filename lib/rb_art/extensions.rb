class Integer
  def to_rad
    Math::PI * self
  end
end

class Float
  def to_rad
    Math::PI * self
  end  
end

class Array
  def scramble
    self.sample count
  end

  def round_indexer idx
    idx = idx % count
    self[idx]
  end

  def each_i_first_last(&block)
    n = count
    each_with_index { |v, idx|
      block&.call v, idx, idx.zero?, idx == n - 1
    }
  end
end