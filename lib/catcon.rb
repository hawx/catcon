require 'ast_ast'
require 'clive/output'

class Hash
  def stringify!
    keys.each do |key|
      self[key.to_s] = delete(key)
    end
    self
  end
end

class Ast::Tokens
  def to_a
    map {|i|
      if i.value.respond_to?(:to_a)
        [i.type, i.value.to_a]
      else
        i.to_a
      end
    }
  end
end

class Stack
  def initialize(arr=[])
    @stk = arr.dup
  end

  def size
    @stk.size
  end

  def pop(n=nil)
    n ? @stk.pop(n) : @stk.pop
  end

  def push(*vals)
    @stk.push(*vals)
  end

  def top
    @stk.last
  end

  def clear
    @stk = []
  end

  def to_a
    @stk
  end

  def inspect
    @stk.to_s[1..-2] + " <"
  end
end



class Catcon

  class Lexer < Ast::Tokeniser
    rule :open,  /\[/
    rule :close, /\]/

    rule(:str, /".*?"|'.*?'/)        {|i| i[1..-2] }
    rule(:num, /\d+/)                {|i| i.to_i }
    rule(:single, /:(\w+[!?]?|\S)/)  {|i| i[1..-1] }
    rule(:fun, /(\w+[!?]?|\S)/)
  end

  attr_accessor :funcs

  DEFAULTS = {
    :stdout => $stdout,
    :stderr => $stderr,
    :stdin  => $stdin,
    :debug  => false
  }

  def initialize(opts={})
    @funcs = {}
    @opts  = DEFAULTS

    self.eval(BOOT)
    @opts.merge!(opts)
  end

  def parse(str)
    str.gsub!(/^\s*#.*$/, '')
    str.gsub!(/[ ]*(\n|\|)[ ]*/, ' ')
    str.chomp!
    str.strip!

    tokens = Lexer.tokenise(str)
    a,i = _parse(tokens)
    a
  end

  def _parse(tokens, i=0)
    r = Ast::Tokens.new

    loop do
      curr = tokens[i]

      break if i >= tokens.size
      break if curr.type == :close

      if curr.type == :single
        r << Ast::Token.new(:stm, Ast::Tokens.new([[:fun, curr.to_a.last]]))
      elsif curr.type == :open
        i += 1
        a, i = _parse(tokens, i)
        r << Ast::Token.new(:stm, a)
      else
        r << curr
      end

      i += 1
    end

    return r, i
  end

  def debug(str, type=:normal)
    return unless @opts[:debug]

    puts case type
         when :error then str.red
         when :warn then str.yellow
         end
  end

  def eval(str, stk=Stack.new)
    tokens = parse(str)
    debug tokens.to_a.inspect

    _eval(tokens, stk)
  end

  def _eval(tokens, stk)
    tokens.each do |type, value|
      debug stk.to_a.map {|i| i.respond_to?(:to_a) ? i.to_a : i }

      case type
      when :fun

        if has_defined?(value)
          _eval find_defined(value), stk
        elsif has_builtin?(value)
          find_builtin(value).call(self, stk)
        else
          raise "Could not find function: #{value}"
        end

      when :stm
        # push the statement on as a string, it will later be used in a call
        # to #eval where it will be turned into tokens.
        stk.push(value)

      else
        stk.push(value)
      end
    end

    stk
  end

  def find(name, table)
    if table.has_key?(name)
      table[name]
    elsif ALIASES.has_key?(name) && table.has_key?(ALIASES[name])
      table[ALIASES[name]]
    end
  end

  def find_defined(name)
    find name, @funcs
  end

  def has_defined?(name)
    find_defined(name) != nil
  end

  def find_builtin(name)
    find name, FUNCTIONS
  end

  def has_builtin?(name)
    find_builtin(name) != nil
  end

  # Yeah...
  FUNCTIONS_RUBY = {

    'true'  => lambda {|e,stk| stk.push true },
    'false' => lambda {|e,stk| stk.push false },
    'nil'   => lambda {|e,stk| stk.push nil },

    # @param1 [Boolean] condition
    # @param3 [Statement] if clause
    # @example
    #   true ["was true"] :if
    'if' => lambda {|e,stk|
      t, cond = stk.pop, stk.pop
      e._eval(t, stk) if cond
    },

    'unless' => lambda {|e,stk|
      f, cond = stk.pop, stk.pop
      e._eval(f, stk) unless cond
    },

    # Provide an alias for a function
    # @example
    #   "lte? "<=" :alias
    'alias' => lambda {|e, stk|
      ALIASES[stk.pop] = stk.pop
    }

  }

  FUNCTIONS = {
    builtin:   -> e,stk { puts FUNCTIONS.keys.join(', ') },
    functions: -> e,stk { puts e.funcs.keys.join(', ') },
    aliases:   -> e,stk { puts ALIASES },

    print:    -> e,stk { puts(stk.top) },
    to_s:     -> e,stk { stk.top.to_s },

    ## STACK OPERATIONS

    pop:      -> e,stk { stk.pop },
    dup:      -> e,stk { stk.push(stk.top) },
    swap:     -> e,stk { stk.push(*stk.pop(2).reverse) },
    drop:     -> e,stk { stk.clear },
    stk_size: -> e,stk { stk.push(stk.size) },

    ## ARITHMETIC OPERATIONS

    prod:     -> e,stk { stk.push(stk.pop * stk.pop) },
    add:      -> e,stk { stk.push(stk.pop + stk.pop) },
    sub:      -> e,stk { a,b = *stk.pop(2); stk.push(a - b) },
    div:      -> e,stk { a,b = *stk.pop(2); stk.push(a / b) },
    mod:      -> e,stk { a,b = *stk.pop(2); stk.push(a % b) },

    ## BOOLEAN OPERATIONS

    # true false :or #=> true
    or:       -> e,stk { stk.push(stk.pop || stk.pop) },
    # true false :and #=> false
    and:      -> e,stk { stk.push(stk.pop && stk.pop) },

    ## COMPARATIVE OPERATIONS

    # 3 3 :eq? #=> true as 3 == 3
    # 2 3 :eq? #=> false
    eq?:      -> e,stk { stk.push(stk.pop == stk.pop) },
    # 2 3 :gt? #=> true as 3 > 2
    # 3 2 :gt? #=> false
    gt?:      -> e,stk { stk.push(stk.pop > stk.pop) },
    # 3 2 :lt? #=> true as 2 < 3
    # 2 3 :lt? #=> false
    lt?:      -> e,stk { stk.push(stk.pop < stk.pop) },

    ## OTHERS

    # @param1 [String] name
    # @param2 [Statement] body
    # @example
    #   "NAME" [...] :DEFINE
    define: -> e,stk {
      stms = stk.pop
      name = stk.pop
      e.funcs[name] = stms
    },

    # @param1 [Boolean] condition
    # @param2 [Statement] else clause
    # @param3 [Statement] if clause
    # @example
    #   true ["was false"] ["was true"] :ifelse
    ifelse: -> e,stk {
      t, f, cond = stk.pop, stk.pop, stk.pop
      e._eval(cond ? t : f, stk)
    },

    # Calls the statement at the top of the stack.
    # @example
    #   ["called" :print] :call
    call: -> e,stk {
      r = e._eval(stk.pop, stk)
      stk.push(r)
      stk.pop
    },

    # Repeatadly applies the function
    # @example
    #   1 [ inc ] 5 times
    #   ;=> [6]
    times: -> e,stk {
      n, f = stk.pop, stk.pop
      n.to_i.times { e._eval(f, stk) }
    },

    # Binary recursion operator
    #
    # @first   termination condition
    # @second  termination action
    # @third   how to split up the data
    # @fourth  how to put the two pieces back together
    bin_rec: -> e,stk {
      term_cond, term_act, arg_rel, res_rel = stk.pop, stk.pop, stk.pop, stk.pop

    }
  }.stringify!.merge(FUNCTIONS_RUBY)



  ALIASES = {}

  BOOT = <<-EOS
    'add'  '+' alias
    'prod' '*' alias
    'sub'  '-' alias
    'div'  '/' alias
    'mod'  '%' alias

    'inc' [ 1 add ] define
    'dec' [ 1 sub ] define

    'sum' [
      2 stk_size gt?
      [ + sum ]
      if
    ] define

    'eq?'  '=' alias
    'gt?'  '>' alias
    'lt?'  '<' alias

    'not' [
      [true]
      [false]
      ifelse
    ] define

    'not' '!' alias

    'lte?' [
      gt? !
    ] define

    'gte?' [
      lt? !
    ] define

    'lte?' '<=' alias
    'gte?' '>=' alias

    'empty?' [
      stk_size 0 eq?
    ] define

    'small?' [
      stk_size 1 lte?
    ] define
  EOS

end
