class Maybe
  def self.pure(x)
    Just.new(x)
  end
end

class Just < Maybe
  def initialize(x)
    @x = x
  end

  def *(other)
    Just.new(@x.call(other.instance_variable_get(:@x)))
  end

  def fmap
    Just.new(yield @x)
  end

  def bind
    yield @x
  end

  def ==(other)
    other.is_a?(Just) && other.instance_variable_get(:@x) == @x
  end

  def to_s
    "Just(#{@x})"
  end
end

class Nothing < Maybe
  def fmap
    self
  end

  def *(other)
    self
  end

  def bind
    self
  end

  def ==(other)
    other.is_a?(Nothing)
  end

  def to_s
    "Nothing"
  end
end
