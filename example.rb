require 'parslet'

class Smalltalk < Parslet::Parser
    root :smalltalk

    rule(:smalltalk) { str("a").as(:nigel).repeat(2)}
  end

  puts Smalltalk.new.parse('aa').inspect