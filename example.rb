require 'parslet'

class Smalltalk < Parslet::Parser
    root :smalltalk

    rule(:smalltalk) { str("test").as(:nigel) >> str("bob").as("fred")}
  end

  puts Smalltalk.new.parse('testbob').inspect