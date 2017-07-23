struct Int
  def to_byte_array
    x = self
    result = [] of self
    until x == 0
      result = [x & 0xff] + result
      x = x >> 8
    end
    result
  end
end
