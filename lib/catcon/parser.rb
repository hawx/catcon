module Catcon

  class Parser

    class Lexer < Ast::Tokeniser
      rule(:stmt,    /\[(.*?)\]/m)   {|i| [Parser.parse(i[1])] }
      rule(:list,    /\((.*?)\)/m)   {|i| i.first }
      rule(:string,  /"(.*?)"/m)     {|i| i.first }
      rule(:single,  /:([^\s]+)/)    {|i| [[i[1]]] }
      rule(:func,    /[^\s]+/)
    end

    def self.parse(str)
      str = str.split("\n").map {|i| i.lstrip }.find_all {|i| i[0] != ";" }.join("\n")
      Lexer.dup.tokenise(str).to_a.map(&:last)
    end

  end

end
