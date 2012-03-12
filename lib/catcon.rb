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
  extend self

  def colour(str, code)
    "\e[#{code}m#{str}\e[0m"
  end

  class Error < ::Exception
    def initialize(msg=nil, backtrace=[], stack=[])
      @backtrace = backtrace
      msg += "\n    " + Catcon.colour("Stack: ", 90) + stack.inspect
      super(msg)
    end

    def backtrace
      @backtrace.map {|i| Catcon.colour("Trace: ", 90) + i }
    end
  end

  # When there isn't enough on the stack raise this!
  class InsufficientStackError < Error; end
  # When a stack contains the wrong values for the function called
  class IncorrectTypeError < Error; end
  # When a function is called which has not been defined
  class UndefinedError < Error; end


  def new(opts={})
    @opts = opts
    Interpreter.new(opts)
  end

  def debug(str, level=nil)
    m = {
      :error   => 1, # red
      :warn    => 3, # yellow
      :success => 2  # green
    }
    puts "\e[#{m[level]}m#{str}\e0m" if @opts[:debug]
  end

end
