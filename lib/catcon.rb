require 'ast_ast'

class Ast::Tokens
  def to_a
    self.collect {|i|
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
    @stk.to_s + "<"
  end
end



class Catcon

  class Lexer < Ast::Tokeniser
    rule(:str, /".*?"/)     {|i| i[1..-2] }
    rule(:num, /\d+/)       {|i| i.to_f }
    rule(:fun, /:[^ \]]+/)    {|i| i[1..-1].to_sym }

    rule :open, /\[/
    rule :close, /\]/
    
    rule(:true, /true/)     {|i| true }
    rule(:false, /false/)   {|i| false }
  end
  
  

  attr_accessor :funcs
  
  def initialize(stdout=$stdout, stderr=$stderr)
    @stdout = stdout
    @stderr = stderr
    @funcs  = {}
    
    self.eval(BOOT)
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
      
      if curr.type == :open
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
  
  def eval(str, stk=Stack.new)
    tokens = parse(str)
    _eval(tokens, stk)
  end
  
  def _eval(tokens, stk)
    tokens.each do |type, value|
      case type
      when :fun
        if FUNCTIONS.has_key?(value)
          FUNCTIONS[value].call(self, stk)
          
        elsif ALIASES.has_key?(value)
          FUNCTIONS[ALIASES[value]].call(self, stk)
          
        elsif @funcs.has_key?(value)
          stk = _eval(@funcs[value], stk)
        
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
  
  ALIASES = {
    :* => :prod,
    :+ => :add,
    :- => :sub,
    :/ => :div,
    :% => :mod,
    
    :'=' => :eq?,
    :>   => :gt?,
    :<   => :lt?,
    :>=  => :gte?,
    :<=  => :lte?
  }
  
  FUNCTIONS = {
    print:    -> e,stk { puts(stk.top) },
    to_s:     -> e,stk { stk.top.to_s },
    
  ## STACK OPERATIONS
    
    pop:      -> e,stk { stk.pop },
    dup:      -> e,stk { stk.push(stk.top) },
    swap:     -> e,stk { stk.push(*stk.pop(2).reverse) },
    drop:     -> e,stk { stk.clear },
    stk_size: -> e,stk { stk.push(stk.size) },
    
    # SMALL?:   -> e,stk { stk.size <= 1 },
    
  ## ARITHMETIC OPERATIONS
  
    prod:     -> e,stk { stk.push(stk.pop * stk.pop) },
    add:      -> e,stk { stk.push(stk.pop + stk.pop) },
    sub:      -> e,stk { a,b = *stk.pop(2); stk.push(a - b) },
    div:      -> e,stk { a,b = *stk.pop(2); stk.push(a / b) },
    mod:      -> e,stk { a,b = *stk.pop(2); stk.push(a % b) },
    
  ## BOOLEAN OPERATIONS
    
    # true false :OR #=> true
    or:       -> e,stk { stk.push(stk.pop || stk.pop) },
    # true false :AND #=> false
    and:      -> e,stk { stk.push(stk.pop && stk.pop) },
    
  ## COMPARATIVE OPERATIONS
    
    # 3 3 :EQ? #=> true as 3 == 3
    # 2 3 :EQ? #=> false
    eq?:      -> e,stk { stk.push(stk.pop == stk.pop) },
    # 2 3 :GT? #=> true as 3 > 2
    # 3 2 :GT? #=> false
    gt?:      -> e,stk { stk.push(stk.pop > stk.pop) },
    # 3 2 :LT? #=> true as 2 < 3
    # 2 3 :LT? #=> false
    lt?:      -> e,stk { stk.push(stk.pop < stk.pop) },
    
  ## OTHERS
    
    # @param1 [String] name
    # @param2 [Statement] body
    # @example
    #   "NAME" [...] :DEFINE
    define: -> e,stk {
      stms = stk.pop
      name = stk.pop
      e.funcs[name.to_sym] = stms
    },
    
    # @param1 [Boolean] condition
    # @param2 [Statement] else clause
    # @param3 [Statement] if clause
    # @example
    #   true ["was false"] ["was true"] :IF
    if: -> e,stk {
      t, f, cond = stk.pop, stk.pop, stk.pop
      stk = e._eval(cond ? t : f, stk)
    },
    
    # Calls the statement at the top of the stack.
    # @example
    #   ["called" :print] :call
    call: -> e,stk {
      e._eval(stk.pop, stk)
    },
    
    # Provide an alias for a function
    # @example
    #   "lte? "<=" :alias
    alias: -> e,stk {
      ALIASES[stk.pop] = stk.pop
    }
  }
  
  BOOT = <<-EOS
    "invert" [
      [true]
      [false]
      :if
    ] :define
  
    "lte?" [
      :gt? :invert
    ] :define

    "gte?" [
      :lt? :invert
    ] :define
    
    "lte?" "<=" :alias
    "gte?" ">=" :alias
    
    "small?" [
      :stk_size 1 :lte?
    ] :define
  EOS
  
  # Basic Types
  
  class Num
  
  end
  
  class Bool
  
  end
  
  class Char
  
  end
  
  class List < ::Array
  
  end

end
