module Catcon

  BUILTIN = {

    ## Reflection

    'functions' => proc {|e,s| s.push(List.new(e.table.defined)) },

    # Basic I/O

    'print' => proc {|e,s| e.opts[:stdout].puts s.top },
    'input' => proc {|e,s| s.push e.opts[:stdin].gets },
    'read'  => proc {|e,s| s.push File.read(s.pop) },
    'eval'  => proc {|e,s| e.eval s.pop },

    # Stack operations

    'pop'   => proc {|e,s| s.pop },
    'dup'   => proc {|e,s| s.push(s.top) },
    'swap'  => proc {|e,s| s.push *s.pop(2).reverse },
    'swapp' => proc {|e,s| a,b,c = *s.pop(3); s.push b, a, c },
    'drop'  => proc {|e,s| s.clear },
    'size'  => proc {|e,s| s.push(s.size) },

    ## Arithmetic operations

    'prod' => proc {|e,s| s.push(s.pop * s.pop) },
    'add'  => proc {|e,s| s.push(s.pop + s.pop) },
    'sub'  => proc {|e,s| s.push(s.pop - s.pop) },
    'div'  => proc {|e,s| s.push(s.pop / s.pop) },
    'mod'  => proc {|e,s| s.push(s.pop % s.pop) },

    ## Logical

    'true'  => proc {|e,s| s.push true },
    'false' => proc {|e,s| s.push false },
    'nil'   => proc {|e,s| s.push nil },

    'or'  => proc {|e,s| a,b = *s.pop(2); s.push(a || b) },
    'and' => proc {|e,s| a,b = *s.pop(2); s.push(a && b) },
    'not' => proc {|e,s| s.push(!s.pop) },

    'eq?' => proc {|e,s| s.push(s.pop == s.pop) },
    'gt?' => proc {|e,s| s.push(s.pop > s.pop) },
    'lt?' => proc {|e,s| s.push(s.pop < s.pop) },

    ## Control flow

    'if' => proc {|e,s|
      cond, t = *s.pop(2)
      e.run(t) if cond
    },

    'unless' => proc {|e,s|
      cond, f = *s.pop(2)
      e.run(f) unless cond
    },

    'ifelse' => proc {|e,s|
      cond, f, t = *s.pop(3)
      e.run(cond ? t : f)
    },

    'call' => proc {|e,s|
      r = e.run(s.pop)
      s.push(r)
      s.pop
    },

    'times' => proc {|e,s|
      f, n = *s.pop(2)
      n.to_i.times { e.run(f) }
    },

    ## Definition

    'alias'  => proc {|e,s| e.alias(s.pop, s.pop) },

    'define' => proc {|e,s|
      stms = s.pop
      name = s.pop
      e.define(name, stms)
    }
  }

end
