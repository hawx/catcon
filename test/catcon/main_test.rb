$: << File.dirname(__FILE__) + '/..'
require 'helper'

class MainTest < MiniTest::Unit::TestCase

  def setup
    @stdout = StringIO.new
    @stderr = StringIO.new
    @e = Catcon.new({:stdout => @stdout, :stderr => @stderr})
  end
  
  
  def test_parse
    assert_equal [
      [:num, 1.0],
      [:stm, [
        [:num, 2.0],
        [:stm, [
          [:num, 3.0],
          [:stm, [
            [:num, 4.0]
          ]]
        ]],
        [:num, 2.0]
      ]],
      [:num, 1.0]
    ], @e.parse('1 [2 [3 [4]] 2] 1').to_a
  end


  def test_can_lex
    assert_equal [
      [:str, "a string"],
      [:num, 5.0],
      [:fun, :PRINT],
      [:open, '['],
      [:str, "abc"],
      [:close, ']'],
      [:true, true],
      [:false, false]
    ], Catcon::Lexer.tokenise('"a string" 5 :PRINT ["abc"] true false').to_a
    
    assert_equal [
      [:str, "INVERT"],
      [:open, '['],
      [:open, '['],
      [:false, false],
      [:close, ']'],
      [:open, '['],
      [:true, true],
      [:close, ']'],
      [:fun, :IF],
      [:close, ']'],
      [:fun, :DEFINE]
    ], Catcon::Lexer.tokenise('"INVERT" [[false] [true] :IF] :DEFINE').to_a
  end

## STACK OPERATIONS
  
  def test_pop
    assert_equal [], @e.eval('1 :pop').to_a
  end
  
  def test_dup
    assert_equal [1.0, 1.0], @e.eval('1 :dup').to_a
  end
  
  def test_swap
    assert_equal [2.0, 1.0], @e.eval('1 2 :swap').to_a
  end
  
  def test_drop
    assert_equal [], @e.eval('1 2 3 :drop').to_a
  end
  
  def test_stk_size
    assert_equal [1.0, 2.0, 3.0, 3], @e.eval('1 2 3 :stk_size').to_a
  end
  
  # DERIVED FUNCTIONS
  
  def test_small
    assert_equal [1.0, true], @e.eval('1 :small?').to_a
  end
  
## ARITHMETIC FUNCTIONS

  def test_multiply
    assert_equal [20.0], @e.eval('5 4 :*').to_a
  end
  
  def test_add
    assert_equal [9.0], @e.eval('5 4 :+').to_a
  end
  
  def test_subtract
    assert_equal [1.0], @e.eval('5 4 :-').to_a
  end
  
  def test_divide
    assert_equal [1.25], @e.eval('5 4 :/').to_a
  end
  
  def test_modulus
    assert_equal [1.0], @e.eval('5 4 :%').to_a
  end
  
## BOOLEAN OPERATIONS

  def test_or
    assert_equal [true],  @e.eval('true false :or').to_a
    assert_equal [false], @e.eval('false false :or').to_a
  end
  
  def test_and
    assert_equal [true],  @e.eval('true true :and').to_a
    assert_equal [false], @e.eval('false true :and').to_a
  end
  
## COMPARATIVE OPERATIONS

  def test_eq
    assert_equal [true],  @e.eval('1 1 :eq?').to_a
    assert_equal [false], @e.eval('1 2 :eq?').to_a
  end
  
  def test_gt
    assert_equal [true],  @e.eval('1 2 :gt?').to_a
    assert_equal [false], @e.eval('3 2 :gt?').to_a
  end
  
  def test_lt
    assert_equal [true],  @e.eval('2 1 :lt?').to_a
    assert_equal [false], @e.eval('2 3 :lt?').to_a
  end
  
  def test_gte
    assert_equal [true],  @e.eval('2 2 :gte?').to_a
    assert_equal [false], @e.eval('3 2 :gte?').to_a
  end
  
  def test_lte
    assert_equal [true],  @e.eval('2 2 :lte?').to_a
    assert_equal [false], @e.eval('2 3 :lte?').to_a
  end
  
## OTHERS

  def test_define
    assert_equal [25], @e.eval(<<-EOS).to_a
      "sq" [ :dup :* ] :define
      5 :sq
    EOS
  end
  
  def test_if
    assert_equal [1.0], @e.eval("true [0] [1] :if").to_a
    assert_equal [0.0], @e.eval("false [0] [1] :if").to_a
  end
  
  def test_call
    assert_equal [],    @e.eval('[1]').to_a
    assert_equal [1.0], @e.eval('[1] :call').to_a
  end

end