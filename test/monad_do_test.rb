require "test_helper"
require_relative "maybe"
require_relative "list"

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

  def test_list_monad
    result = MonadDo.do(List) do
      x { List.new([1,2,3]) }
      y { List.new([4,5,6]) }
      pure { |x, y| [x, y] }
    end

    assert_equal [[1,4],[1,5],[1,6],[2,4],[2,5],[2,6],[3,4],[3,5],[3,6]], result.to_a
  end
end
