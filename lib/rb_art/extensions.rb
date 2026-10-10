class Integer
  def to_rad() Math::PI * self end
  def is_odd?() self % 2 == 1 end
end

class Float
  def to_rad() Math::PI * self end  
end

class Array
  def scramble() self.sample count end
  def round_indexer(idx) self[idx % count] end

  def each_i_first_last(&block)
    n = count
    each_with_index { |v, idx|
      block&.call v, idx, idx.zero?, idx == n - 1
    }
  end
end