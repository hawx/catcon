module Catcon

  class Interpreter

    # When there isn't enough on the stack raise this!
    class InsufficientStackError < ArgumentError; end

    attr_reader :stack, :table, :stdout, :stderr, :stdin

    DEFAULTS = {
      :stdout => $stdout,
      :stderr => $stderr,
      :stdin  => $stdin,
      :debug  => false
    }

    def initialize(opts={})
      opts = DEFAULTS.merge(opts)
      @stdout = opts.delete(:stdout)
      @stderr = opts.delete(:stderr)
      @stdin  = opts.delete(:stdin)
      @opts   = opts

      @stack  = Stack.new
      @table  = Table.new(BUILTIN)

      eval "'#{File.dirname(__FILE__)}/boot.cat' read eval"
    end

    def debug(str)
      puts str if @opts[:debug]
    end

    def eval(str)
      tree = Parser.parse(str)
      run tree
      @stack
    end

    def run(tree)
      tree.each do |t|
        case t
        when /\d+/ then @stack.push(t.to_i)
        when /("|').+?("|')/ then @stack.push(t[1..-2])
        when Array then @stack.push(t)
        else
          begin
            @table.run(t, @stack, self)
          rescue ArgumentError => e
            raise InsufficientStackError, "Attempted to call #{t} with stack of #{@stack.inspect}."
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

  end

end
