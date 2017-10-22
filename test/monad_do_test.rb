require "test_helper"
require_relative "maybe"

class MonadDoTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::MonadDo::VERSION
  end

  def test_it_does_something_useful
    result = MonadDo.do(Maybe) do
      x { Just.new(2) }
      y { Just.new(3) }
      pure { |x, y| x + y }
    end

    assert_equal Just.new(5), result
  end

  def test_no_pure
    result = MonadDo.do(Maybe) do
      x { Just.new(2) }
      y { |x| Just.new(3 + x) }
    end

    assert_equal Just.new(5), result
  end

  def test_allows_reassigning_names
    result = MonadDo.do(Maybe) do
      x { Just.new(2) }
      x { |x| Just.new(3 + x) }
      pure { |x| 3 + x }
    end

    assert_equal Just.new(8), result
  end
end
