require_relative '../helper'

describe Catcon::Interpreter do

  let(:stdin)  { StringIO.new }
  let(:stdout) { StringIO.new }
  subject { Catcon::Interpreter.new(:stdin => stdin, :stdout => stdout) }

  it 'pushes numbers onto the stack' do
    subject.run(['1', '2', '3'])
    subject.stack.to_a.must_equal [1, 2, 3]
  end

  it 'evaluates functions' do
    subject.run(['1', '2', 'add', '4', 'prod'])
    subject.stack.to_a.must_equal [12]
  end

  it 'pushes strings onto the stack' do
    subject.run(['"hello"', '"good bye"'])
    subject.stack.to_a.must_equal ['hello', 'good bye']
  end

  it 'pushes statements onto the stack' do
    subject.run(['1', ['inc', 'dup']])
    subject.stack.to_a.must_equal [1, ['inc', 'dup']]
  end

  describe 'builtin functions' do

    describe '#functions' do
      it 'pushes a List of defined functions on to the stack' do
        subject.eval 'functions'
        subject.stack.to_a.flatten.must_include 'functions' # etc
      end
    end

    describe '#print' do
      it 'prints top of stack to STDOUT' do
        subject.eval '4 3 prod print'
        stdout.string.must_equal "12\n"
      end
    end

    describe '#input' do
      it 'gets input from STDIN' do
        subject.eval 'input'
        stdin.puts 'help'
        subject.stack.must_equal ['help']
      end
    end

    describe '#pop' do
      it 'removes the top of the stack' do
        subject.eval '1 2 3 pop'
        subject.stack.to_a.must_equal [1, 2]
      end
    end

    describe '#dup' do
      it 'duplicates the top of the stack' do
        subject.eval '1 dup'
        subject.stack.must_equal [1, 1]
      end
    end

    describe '#swap' do
      it 'swaps the top two items on the stack' do
        subject.eval '1 2 3 swap'
        subject.stack.must_equal [1, 3, 2]
      end
    end

    describe '#swap' do
      it 'swaps the second and third items' do
        subject.eval '1 2 3 4 swapp'
        subject.stack.must_equal [1, 3, 2, 4]
      end
    end

    describe '#drop' do
      it 'clears the stack' do
        subject.eval '1 2 3 4 drop'
        subject.stack.must_equal []
      end
    end

    describe '#size' do
      it 'pushes the size of the stack to the top' do
        subject.eval '1 2 3 size'
        subject.stack.must_equal [1, 2, 3, 3]
      end
    end

    describe '#prod' do
      it 'pushes the product of the top two items' do
        subject.eval '1 2 3 prod'
        subject.stack.must_equal [1, 6]
      end
    end

    describe '#add' do
      it 'pushes the sum of the top two items' do
        subject.eval '1 2 3 add'
        subject.stack.must_equal [1, 5]
      end
    end

    describe '#sub' do
      it 'pushes the difference of the top two items' do
        subject.eval '1 2 3 sub'
        subject.stack.must_equal [1, -1]
      end
    end

    describe '#div' do
      it 'pushes the quotient of the top two items' do
        subject.eval '1 2 3 div'
        subject.stack.must_equal [1, 0]
      end
    end

    describe '#mod' do
      it 'pushes the modulus of the top two items' do
        subject.eval '1 2 3 mod'
        subject.stack.must_equal [1, 1]
      end
    end

    describe '#true' do
      it 'pushes true value' do
        subject.eval 'true'
        subject.stack.must_equal [true]
      end
    end

    describe '#false' do
      it 'pushes false value' do
        subject.eval 'false'
        subject.stack.must_equal [false]
      end
    end

    describe '#nil' do
      it 'pushes nil value' do
        subject.eval 'nil'
        subject.stack.must_equal [nil]
      end
    end

    describe '#or' do
      it 'calculates boolean or of top two items' do
        subject.eval 'true false or'
        subject.stack.must_equal [true]
      end
    end

    describe '#and' do
      it 'calculates boolean and of top two items' do
        subject.eval 'true false and'
        subject.stack.must_equal [false]
      end
    end

    describe '#not' do
      it 'negates the top value' do
        subject.eval 'true not'
        subject.stack.must_equal [false]
      end
    end

    describe '#eq?' do
      it 'checks if top two values are equal' do
        subject.eval '1 2 eq?'
        subject.stack.must_equal [false]
      end
    end

    describe '#gt?' do
      it 'checks if top value is greater than second' do
        subject.eval '1 2 gt?'
        subject.stack.must_equal [true]
      end
    end

    describe '#lt?' do
      it 'checks if top value is less than second' do
        subject.eval '1 2 lt?'
        subject.stack.must_equal [false]
      end
    end

    describe '#if' do
      it 'executes statements if condition is true' do
        subject.eval '1 1 eq? [ "yes" ] if'
        subject.stack.must_equal ['yes']
      end
    end

    describe '#unless' do
      it 'executes statements if condition is false' do
        subject.eval '1 2 eq? [ "no" ] unless'
        subject.stack.must_equal ['no']
      end
    end

    describe '#ifelse' do
      it 'executes second statements if false' do
        subject.eval 'false [ "yes" ] [ "no" ] ifelse'
        subject.stack.must_equal ['yes']
      end

      it 'executes top statements if true' do
        subject.eval 'true [ "no" ] [ "yes" ] ifelse'
        subject.stack.must_equal ['yes']
      end
    end

    describe '#call' do
      it 'calls the quoted statements' do
        subject.eval '1 :inc call'
        subject.stack.must_equal [2]
      end
    end

    describe '#times' do
      it 'repeatedly calls a statement' do
        subject.eval '1 :inc 5 times'
        subject.stack.must_equal [6]
      end
    end

    describe '#alias' do
      it 'sets an alias for the function' do
        subject.eval '"inc" "cray" alias'
        subject.eval '1 inc cray'
        subject.stack.must_equal [3]
      end
    end

    describe '#define' do
      it 'defines a function' do
        subject.eval '"sq" [ dup prod ] define'
        subject.eval '2 sq'
        subject.stack.must_equal [4]
      end
    end

  end

  describe 'some example functions to test' do

    it 'can calculate factorials' do
      subject.eval 'factorial [ dup 0 = [pop 1] [dup dec factorial prod] if ] define'
      subject.eval '7 factorial'
      subject.stack.must_equal [720]
    end

  end

end
