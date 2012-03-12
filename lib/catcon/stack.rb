module Catcon

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
      @stk.last
    end

    def clear
      @stk = []
    end

    def to_a
      @stk
    end

    def inspect
      @stk.inspect
    end

    def must_equal(other)
      other.to_a == @stk
    end
  end

end
