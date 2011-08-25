require 'ast_ast'

class Catcon

  class Lexer < Ast::Tokeniser
    rule(:str, /".*?"/)     {|i| i[1..-2] }
    rule(:num, /\d+/)       {|i| i.to_f }
    rule(:fun, /:[^ ]+/)    {|i| i[1..-1].to_sym }
    rule(:stm, /\[.*?\]/)   {|i| i[1..-2] }
    
    rule :break, /[ ]*(\n|\|)[ ]*/
  end

  attr_accessor :funcs
  
  def initialize(stdout=$stdout, stderr=$stderr)
    @stdout = stdout
    @stderr = stderr
    @funcs  = {}
  end
  
  def eval(str, stk=[])
    tokens = Lexer.tokenise(str).reject {|i| i.type == :break }

    tokens.each do |type, value|
      case type
      when :fun
        if FUNCTIONS.has_key?(value)
          FUNCTIONS[value].call(self, stk)
          
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
  
  
  FUNCTIONS = {
    :PRINT => proc {|e,stk| puts stk.first },
    :* => proc {|e,stk| stk.push(stk.pop * stk.pop) },
    :+ => proc {|e,stk| stk.push(stk.pop + stk.pop) },
    :EQ? => proc {|e,stk| stk.push(stk.pop == stk.pop) },
    :DUP => proc {|e,stk| stk.push(stk.first) },
    :DEFINE => proc {|e,stk|
      stms = stk.pop
      name = stk.pop
      e.funcs[name.to_sym] = stms
    },
    :IF => proc {|e,stk| 
      t, f, cond = stk.pop, stk.pop, stk.pop
      stk = e.eval(cond ? t : f, stk)
    }
  }

end