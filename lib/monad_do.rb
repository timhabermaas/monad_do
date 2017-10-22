require "monad_do/version"

module MonadDo
  class Syntax < BasicObject

    attr_reader :lines

    class Line
      attr_reader :variable, :block, :monad_class

      def initialize(monad_class, variable = UnusedVariable, block)
        @variable = variable
        @block = block
        @monad_class = monad_class
      end

      def run(variables, context)
        dependencies = @block.parameters.map(&:last)
        arguments = dependencies.map { |name| variables.fetch(name) }
        context.instance_exec(*arguments, &@block)
      end
    end

    class Bind < Line
      def run(variables, context)
        if block_given?
          super.bind do |x|
            yield(variables.merge(variable => x))
          end
        else
          super
        end
      end
    end

    class Pure < Line
      def run(variables, context)
        monad_class.pure(super)
      end
    end

    class Let < Line
      def run(variables, context)
        dependencies = @block.parameters.map(&:last)
        arguments = dependencies.map { |name| variables.fetch(name) }
        x = context.instance_exec(*arguments, &@block)
        if block_given?
          yield(variables.merge(variable => x))
        else
          raise "`let` was used as the last statement in do notation. Pretty useless."
        end
      end
    end

    UnusedVariable = BasicObject.new

    def initialize(monad_class)
      @monad_class = monad_class
      @lines = []
    end

    def bind(v = UnusedVariable, &block)
      @lines << Bind.new(@monad_class, v, block)
    end

    def let(v, &block)
      @lines << Let.new(@monad_class, v, block)
    end

    def pure(&block)
      @lines << Pure.new(@monad_class, UnusedVariable, block)
    end

    def method_missing(method, *args, &block)
      @lines << Bind.new(@monad_class, method, block)
    end

  end

  def self.do(monad_class, &block)
    s = Syntax.new(monad_class)
    s.instance_eval(&block)
    # We are hijacking the context of the block in order to implement the DSL:
    # `x { foo }` is equivalent to `s.x { foo }`.
    # But by doing so we're also changing the context of the block. It's executed
    # in the context of `s :: Syntax` as well. This leads to misleading error messages
    # because the call to `foo` will try to create a new bind and the return value is
    # messed up.
    #
    # That's why we capture the scope in which `MonadDo.do` was called through the following trick/hack.
    # Credits to https://www.dan-manges.com/blog/ruby-dsls-instance-eval-with-delegation
    context = eval "self", block.binding
    run(s.lines, monad_class, context)
  end

  def self.run(lines, monad_class, context, variables = {})
    line = lines.first
    if lines.size == 1
      return line.run(variables, context)
    end

    line.run(variables, context) do |scope|
      run(lines[1..-1], monad_class, context, scope)
    end
  end
end
