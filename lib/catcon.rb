require 'ast_ast'

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

$: << File.dirname(__FILE__)

require 'catcon/stack'
require 'catcon/table'
require 'catcon/list'

require 'catcon/builtin'
require 'catcon/parser'
require 'catcon/interpreter'

module Catcon

  def self.new(opts={})
    Interpreter.new(opts)
  end

end
