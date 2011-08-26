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
    @stk.first
  end
  
  def clear
    @stk = []
  end
  
  def to_a
    @stk
  end
  
  def inspect
    "{" + @stk.to_s[1..-2] + " <"
  end
end

class Catcon

  class Lexer < Ast::Tokeniser
    rule(:str, /".*?"/)     {|i| i[1..-2] }
    rule(:num, /\d+/)       {|i| i.to_f }
    rule(:fun, /:[^ ]+/)    {|i| i[1..-1].to_sym }

    rule(:open, /\[/)
    rule :close, /\]/
    
    rule(:true, /true/)     {|i| true }
    rule(:false, /false/)   {|i| false }
  end

  attr_accessor :funcs
  
  def initialize(stdout=$stdout, stderr=$stderr)
    @stdout = stdout
    @stderr = stderr
    @funcs  = {}
    
    @funcs[:small?] = ":stk_size 1 :lte?"
   # self.eval(BOOT)
  end
  
  
  def parse(str)
    str.gsub!(/^\s*#.*$/, '')
    str.gsub!(/[ ]*(\n|\|)[ ]*/, ' ')
    
    tokens = Lexer.tokenise(str)
    _parse(tokens)
  end

  def _parse(tokens, i=0)
    r = Ast::Tokens.new

    until tokens[i].type == :close
    
      if tokens[i].type == :open
        i += 1
        r << Ast::Token.new(:stm, _parse(tokens, i))
      else
        r << tokens[i]
      end
      
      i += 1
      break unless i < tokens.size
    end
    r
  end
  
  def eval(str, stk=Stack.new)
    tokens = parse(str)

    tokens.each do |type, value|
      case type
      when :fun
        if FUNCTIONS.has_key?(value)
          FUNCTIONS[value].call(self, stk)
          
        elsif ALIASES.has_key?(value)
          FUNCTIONS[ALIASES[value]].call(self, stk)
          
        elsif @funcs.has_key?(value)
          stk = eval(@funcs[value], stk)
        
        else
          puts "Could not find function: #{value}"
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
    :* => :PROD,
    :+ => :ADD,
    :- => :SUB,
    :/ => :DIV,
    :% => :MOD
  }
  
  FUNCTIONS = {
    PRINT:    -> e,stk { puts(stk.top) },
    
  ## STACK OPERATIONS
    
    POP:      -> e,stk { stk.pop },
    DUP:      -> e,stk { stk.push(stk.top) },
    SWAP:     -> e,stk { stk.push(*stk.pop(2).reverse) },
    DROP:     -> e,stk { stk.clear },
    STK_SIZE: -> e,stk { stk.push(stk.size) },
    
    # SMALL?:   -> e,stk { stk.size <= 1 },
    
  ## ARITHMETIC OPERATIONS
  
    PROD:     -> e,stk { stk.push(stk.pop * stk.pop) },
    ADD:      -> e,stk { stk.push(stk.pop + stk.pop) },
    SUB:      -> e,stk { a,b = *stk.pop(2); stk.push(a - b) },
    DIV:      -> e,stk { a,b = *stk.pop(2); stk.push(a / b) },
    MOD:      -> e,stk { a,b = *stk.pop(2); stk.push(a % b) },
    
  ## BOOLEAN OPERATIONS
    
    # true false :OR #=> true
    OR:       -> e,stk { stk.push(stk.pop || stk.pop) },
    # true false :AND #=> false
    AND:      -> e,stk { stk.push(stk.pop && stk.pop) },
    
  ## COMPARATIVE OPERATIONS
    
    # 3 3 :EQ? #=> true as 3 == 3
    # 2 3 :EQ? #=> false
    EQ?:      -> e,stk { stk.push(stk.pop == stk.pop) },
    # 2 3 :GT? #=> true as 3 > 2
    # 3 2 :GT? #=> false
    GT?:      -> e,stk { stk.push(stk.pop > stk.pop) },
    # 3 2 :LT? #=> true as 2 < 3
    # 2 3 :LT? #=> false
    LT?:      -> e,stk { stk.push(stk.pop < stk.pop) },
    
    GTE?:     -> e,stk { stk.push(stk.pop >= stk.pop) },
    LTE?:     -> e,stk { stk.push(stk.pop <= stk.pop) },
    
  ## OTHERS
    
    # @param1 [String] name
    # @param2 [Statement] body
    # @example
    #   "NAME" [...] :DEFINE
    DEFINE: -> e,stk {
      stms = stk.pop
      name = stk.pop
      e.funcs[name.to_sym] = stms
    },
    
    # @param1 [Boolean] condition
    # @param2 [Statement] else clause
    # @param3 [Statement] if clause
    # @example
    #   true ["was false"] ["was true"] :IF
    IF: -> e,stk {
      t, f, cond = stk.pop, stk.pop, stk.pop
      stk = e.eval(cond ? t : f, stk)
    }
  }

end