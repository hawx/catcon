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
      [:num, 1],
      [:stm, [
        [:num, 2],
        [:stm, [
          [:num, 3],
          [:stm, [
            [:num, 4]
          ]]
        ]],
        [:num, 2]
      ]],
      [:num, 1]
    ], @e.parse('1 [2 [3 [4]] 2] 1').to_a
  end


  def test_can_lex
    assert_equal [
      [:str, "a string"],
      [:num, 5],
      [:fun, 'print'],
      [:open, '['],
      [:str, "abc"],
      [:close, ']'],
      [:fun, 'true'],
      [:fun, 'false']
    ], Catcon::Lexer.tokenise('"a string" 5 print ["abc"] true false').to_a

    assert_equal [
      [:str, "INVERT"],
      [:open, '['],
      [:open, '['],
      [:fun, 'false'],
      [:close, ']'],
      [:open, '['],
      [:fun, 'true'],
      [:close, ']'],
      [:fun, 'if'],
      [:close, ']'],
      [:fun, 'define']
    ], Catcon::Lexer.tokenise('"INVERT" [[false] [true] if] define').to_a
  end

## STACK OPERATIONS

  def test_pop
    assert_equal [], @e.eval('1 pop').to_a
  end

  def test_dup
    assert_equal [1, 1], @e.eval('1 dup').to_a
  end

  def test_swap
    assert_equal [2, 1], @e.eval('1 2 swap').to_a
  end

  def test_drop
    assert_equal [], @e.eval('1 2 3 drop').to_a
  end

  def test_stk_size
    assert_equal [1, 2, 3, 3], @e.eval('1 2 3 stk_size').to_a
  end

  # DERIVED FUNCTIONS

  def test_small
    assert_equal [1, true], @e.eval('1 small?').to_a
  end

## ARITHMETIC FUNCTIONS

  def test_multiply
    assert_equal [20], @e.eval('5 4 *').to_a
  end

  def test_add
    assert_equal [9], @e.eval('5 4 +').to_a
  end

  def test_subtract
    assert_equal [1], @e.eval('5 4 -').to_a
  end

  def test_divide
    assert_equal [1.25], @e.eval('5 4 /').to_a
  end

  def test_modulus
    assert_equal [1], @e.eval('5 4 %').to_a
  end

## BOOLEAN OPERATIONS

  def test_or
    assert_equal [true],  @e.eval('true false or').to_a
    assert_equal [false], @e.eval('false false or').to_a
  end

  def test_and
    assert_equal [true],  @e.eval('true true and').to_a
    assert_equal [false], @e.eval('false true and').to_a
  end

## COMPARATIVE OPERATIONS

  def test_eq
    assert_equal [true],  @e.eval('1 1 eq?').to_a
    assert_equal [false], @e.eval('1 2 eq?').to_a
  end

  def test_gt
    assert_equal [true],  @e.eval('1 2 gt?').to_a
    assert_equal [false], @e.eval('3 2 gt?').to_a
  end

  def test_lt
    assert_equal [true],  @e.eval('2 1 lt?').to_a
    assert_equal [false], @e.eval('2 3 lt?').to_a
  end

  def test_gte
    assert_equal [true],  @e.eval('2 2 gte?').to_a
    assert_equal [false], @e.eval('3 2 gte?').to_a
  end

  def test_lte
    assert_equal [true],  @e.eval('2 2 lte?').to_a
    assert_equal [false], @e.eval('2 3 lte?').to_a
  end

## OTHERS

  def test_define
    assert_equal [25], @e.eval(<<-EOS).to_a
      "sq" [ dup * ] define
      5 sq
    EOS
  end

  def test_if
    assert_equal [1], @e.eval("true [1] if").to_a
    assert_equal [],  @e.eval("false [1] if").to_a
  end

  def test_unless
    assert_equal [1], @e.eval("false [1] unless").to_a
    assert_equal [],  @e.eval("true [1] unless").to_a
  end

  def test_ifelse
    assert_equal [1], @e.eval("true [0] [1] ifelse").to_a
    assert_equal [0], @e.eval("false [0] [1] ifelse").to_a
  end

  def test_call
    assert_equal [[[:num, 1]]], @e.eval('[1]').to_a.map {|i| i.to_a }
    assert_equal [1], @e.eval('[1] call').to_a
  end


  def test_factorial
    assert_equal [120], @e.eval(<<-EOS).to_a
      "fact" [
        dup 0 eq?
        [dup 1 - fact *]
        [pop 1]
        ifelse
      ] define

      5 fact
    EOS
  end


  def test_fibonacci
    assert_equal [], @e.eval(<<-EOS).to_a
      "fib" [
        dup dup 1 eq? swap 0 eq? or not
        [
          dup  1 - fib
          swap 2 - fib
          +
        ]
        if
      ] define

      2 fib
    EOS
  end

end
