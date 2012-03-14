module Catcon

  class Table
    def initialize(tbl={})
      @tbl = Hash[ tbl.map {|k,v| [k, Function.new(v)] } ]
      @aliases = {}
    end

    def run(f, stk, e)
      if has?(f)
        find(f).call(e, stk)
      else
        warn "Function #{f} not defined"
      end
    end

    def find(f)
      @tbl[f] || (alias?(f) && @tbl[@aliases[f]])
    end

    def has?(f)
      @tbl.key?(f) || alias?(f)
    end

    def alias?(f)
      @aliases.key?(f)
    end

    def defined
      functions + aliases
    end

    def functions
      @tbl.keys
    end

    def aliases
      @aliases.keys
    end

    def define(name, body)
      @tbl[name] = Function.new(body)
    end

    def alias(from, to)
      @aliases[from] = to
    end
  end

end
