require_relative '../helper'

describe Catcon::Function do

  let(:e) { Catcon::Interpreter.new }
  subject { Catcon::Function }

  describe '#call' do
    it 'calls proc if body is a proc' do
      p = proc {|e,s| s.push 'b' }
      f = subject.new(p)
      s = ['a']
      f.call e, s
      s.must_equal ['a', 'b']
    end

    it 'executes statements if not' do
      f = subject.new(['"b"'])
      s = ['a']
      e.instance_variable_set(:@stack, s)
      f.call e, s
      s.must_equal ['a', 'b']
    end
  end

end
