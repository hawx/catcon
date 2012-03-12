module Catcon

  class Interpreter

    attr_reader :stack, :table, :opts

    DEFAULTS = {
      :stdout => $stdout,
      :stderr => $stderr,
      :stdin  => $stdin,
      :debug  => false
    }

    def initialize(opts={})
      @opts   = DEFAULTS.merge(opts)
      @stack  = Stack.new
      @table  = Table.new(BUILTIN)

      eval "'#{File.dirname(__FILE__)}/boot.cat' read eval"
    end

    def eval(str)
      tree = Parser.parse(str)
      run tree
      @stack
    end

    def run(tree)
      tree.each_with_index do |t,i|
        case t
        when /\d+/ then @stack.push(t.to_i)
        when /("|').+?("|')/ then @stack.push(t[1..-2])
        when Array then @stack.push(t)
        else
          begin
            @table.run(t, @stack, self)

          rescue ArgumentError => e
            raise InsufficientStackError.new("Attempted to call #{t}.",
                                             backtrace_for(i, tree),
                                             @stack)

          rescue NoMethodError => e
            type = e.message.split('').last
            raise IncorrectTypeError.new("Attempted to call #{t}. Required a #{type}.",
                                         backtrace_for(i, tree),
                                         @stack)

          rescue TypeError => e
            obj  = e.message.split(' ').first
            type = e.message.split(' ').last
            raise IncorrectTypeError.new("Attempted to call #{t}. Can't convert #{obj} to #{type}.",
                                         backtrace_for(i, tree),
                                         @stack)
          end
        end
      end
    end

    def define(name, stms)
      @table.define(name, proc {|e,s| e.run(stms) })
    end

    def alias(to, from)
      @table.alias to, from
    end

    def backtrace_for(i, tree)
      size = 5
      l = r = ['...']

      left = i - size
      if left < 0
        left = 0
        l = []
      end

      right = i + size
      if right >= tree.size
        right = -1
        r = []
      end

      lside = tree[left..i-1]  rescue []
      rside = tree[i+1..right] rescue []
      item  = [Catcon.colour(tree[i], 36)]

      [(l + lside + item + rside + r).join(' ')]
    end

  end

end
