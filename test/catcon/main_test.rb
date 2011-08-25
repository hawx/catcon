$: << File.dirname(__FILE__) + '/..'
require 'helper'

class MainTest < MiniTest::Unit::TestCase

  def setup
    @stdout = StringIO.new
    @stderr = StringIO.new
    @e = Catcon.new(@stdout, @stderr)
  end

  def test_can_push_to_stack
    assert_equal [5], @e.eval("5")
  end
  
  def test_can_do_sums
    assert_equal [300], @e.eval("25 10 :* 50 :+")
  end
  
  def test_can_test_equality
    assert_equal [true], @e.eval("50 50 :EQ?")
  end

  def test_can_define_functions
    assert_equal [25], @e.eval('"SQ" [:DUP :*] :DEFINE 
                                5 :SQ')
    #assert_equal [25], @e.eval(":DEFINE SQ :DUP :* | 5 :SQUARE")
  end
  
  def test_can_evaluate_if
    assert_equal ["yep"], @e.eval('300 300 :EQ? ["nope"] ["yep"] :IF')
  end

end