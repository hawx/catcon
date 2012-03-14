module Catcon

  class Function

    attr_reader :body, :docs, :meta

    def initialize(body, docs='', meta={})
      @body = body
      @docs = docs
      @meta = meta
    end

    def call(e, s)
      if body.is_a?(Proc)
        body.call(e, s)
      else
        e.run(body)
      end
    end

  end

end
