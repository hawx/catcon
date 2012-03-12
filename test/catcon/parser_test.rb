require_relative '../helper'

describe Catcon::Parser do

  subject { Catcon::Parser }

  it 'parses a list of functions correctly' do
    subject.parse('swap bury pop').must_equal ['swap', 'bury', 'pop']
  end

  it 'parses a string correctly' do
    subject.parse('"string" print').must_equal ['"string"', 'print']
  end

  it 'parses numbers correctly' do
    subject.parse('1 2 3 4 sum').must_equal ['1', '2', '3', '4', 'sum']
  end

  it 'parses quoted functions correctly' do
    subject.parse('1 :inc call').must_equal ['1', ['inc'], 'call']
  end

  it 'parses quoted lists correctly' do
    subject.parse('1 [inc inc] call').must_equal ['1', ['inc', 'inc'], 'call']
  end

  it 'parses lists correctly' do
    subject.parse('(1 2 3) :sum apply').must_equal ['(1 2 3)', ['sum'], 'apply']
  end

end
