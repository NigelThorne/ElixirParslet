# Parslet for Erlang

Parslet for Erlang is based on the Ruby [Parslet](https://github.com/kschiess/parslet/) library of the same name. I've tried to keep the user experience as simiar as possible.

Parslet can parse any PEG grammer. 

A Parser takes text as input and translates it into some data structure that captures the meaning of the text.
Parslets approach is to split that problem into two. First is to read the text and convert it into a tree structure that keeps the significants facts from the input and labels them.
Second you take that tree and transform it into your final tree. 

So, to create a complete 'parser', you write a Parslet Parser and Transformer.

# What's working 

You have a DSL for defining parsers and transformers; and they work! There are no known bugs.

I have implemented a [JSON parser](parslet\test\json_parser_test.exs) (without whitespace) as a proof of completeness. 

Check the test to find a very simple XML parser to show more concepts.
I'll add a guide to the bottom of this document, to help you get your head around how to think about the parsers and transformers. 

# Missing

The error handling is woeful. This parser would ideally pass around line numbers etc. from the source document so you know at what point in your document and grammer the parser failed. This is something that Parslet does quite well.  Given this is missing TDD is your friend here! Don't forget you can test your Parser and Transformer separatly.

# Future 

Primarily I am working on this to learn Elixir. 

Something that is also missing from the original, is the ability to run the parser in several modes.
One mode is as a production parser, which just parses the document to data, so you can transform it, and should be really fast, and should tell you where the text is wrong if it breaks with the grammer. 

Another mode is for when you are in the process of authoring your grammer. In this mode it should give you feedback around where the parser failed. It should detect endless loops in your grammer.

## Usage

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `parslet` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:parslet, "~> 0.1.0"}
  ]
end
```

I'm not sure it's still there. I wrote this code a long time ago :) 

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/parslet](https://hexdocs.pm/parslet).

## Contributing

I'd love someone to optimize this thing. I have done no work on making it fast.

## Getting started

As mentioned before there are some concepts you need to get your hear around. 

You define your parser as a set of rules and a root node. Rules represent things that can be matched. 
The `root` defines the rule that is expected to represent the entire input document.

You define a Parser that's job is to consume the stream of characaters from the input and generate a tree structure that has all the bits you will later need access to labeled. It's not trying to generate your final output, just to give each significant part of the input a name. It's close to the concept of tokenization, but it's aware of the tree structure. This means you have more context when deciding what the meaning of a bit of text it.  Parslet will take your parser definition and apply a brute force attempt to make the text fit the grammer. If we can't find a valid parse tree for the text we error out. 

If the text has a valid parse tree, Parslet returns it. 

Once you have this tree that represents the meaning of the input text, you can then work on transforming it into the desired output shape. 

You do this by defining a transform function that gets applied to your parse tree depth first, recursivly starting from the leaves folding the intermediate tree until you end up with your final structure. 


Let's look at a simple example.

# Hello World example

ok... so lets do an example. 

```elixir
defmodule GreetingParse do
  use Parslet

  root(:greeting)

  rule :greeting do
    str("Hello World")
  end
end

test "parse greeting" do
  assert GreetingParse.parse(~S(Hello World)) == {:ok, "Hello World"}
end
```
`str` is a parser that matches a static string
We get a success and we get the matched text back.

When it doesn't match it will tell you what went wrong. 
```elixir
test "parse greeting" do
  assert GreetingParse.parse(~S(Hi World)) == {:ok, "Hello World"}
end

1) test parse greeting (SimpleMathParserAndTests)
    test/simple_parser_test.exs:14
    Assertion with == failed
    code:  assert GreetingParse.parse(~S"Hi World") == {:ok, "Hello World"}
    left:  {:error, "'Hi World' does not match string 'Hello World'"}
    right: {:ok, "Hello World"}
    stacktrace:
      test/simple_parser_test.exs:15: (test)
```


So let's make it allow both
```elixir
  ...
    rule :greetings do
      one_of([  
        str("Hello World"), 
        str("Hi World")])
    end
  ...

  test "parse greeting" do
    assert GreetingParse.parse(~S(Hello World)) == {:ok, "Hello World"}
    assert GreetingParse.parse(~S(Hi World)) == {:ok, "Hi World"}
  end
```
`one_of` takes a set of parsers that could match, and when applied checks the input against each parser until it finds one that matches. No match means it fails to parse. 

Both paths match the " World" text. We can remove that duplication.
```elixir
    rule :greetings do
      one_of([
        str("Hello"),
        str("Hi")
      ])
      |> str(" World")
    end
```
`|>` lets you chain parsers together. It takes two parsers to make a new parser that matches only if the text remaining after matching the first parser can be matched by the second parser.

Now... let's say we want to record which greating we got. Now we want to capture "Hello" or "Hi" as being significant.
```elixir
  ...
    rule :greetings do
      as(:saluation, one_of([
        str("Hello"),
        str("Hi")
      ]))
      |> str(" World")
    end
  ...

  test "parse greeting" do
    assert GreetingParse.parse(~S(Hello World)) == {:ok, %{saluation: "Hello"}}
    assert GreetingParse.parse(~S(Hi World)) == {:ok, %{saluation: "Hi"}}
  end
```
`as` take a name and a parser. When it matches it returns a key value pair with the name given and the result of the given parser.
Notice the greeting parser no longer returns the whole matched string. Just the bits we labeled as important.

For readability and reusability we can split rules up.

```elixir
  ...
    rule :salutation do
      as(
        :salutation,
        one_of([
          str("Hello"),
          str("Hi")
        ])
      )
    end

    rule :greetings do
      salutation()
      |> str(" World")
    end
  ...
```
You can call rules by name as parsers.

If we still wanted the whole greeting captured, we can do that too
```elixir
    rule :greetings do
      as(
        :greeting,
        salutation()
        |> str(" World")
      )
    end
    ...
  test "parse greeting" do
    assert GreetingParse.parse(~S(Hello World)) == {:ok, %{greeting: %{salutation: "Hello"}}}
    assert GreetingParse.parse(~S(Hi World)) == {:ok, %{greeting: %{salutation: "Hi"}}}
  end
```
That didn't work. This still doesn't capture "World". 
This is because `as` just gives a name to what's being returned by the parser. We already know we are missing the word 'World'

Let's try again. 
```
    rule :greetings do
      salutation()
      |> str(" ")
      |> as(:greeting_scope, str("World"))
    end

  test "parse greeting" do
    assert GreetingParse.parse(~S(Hello World)) ==
             {:ok, %{greeting_scope: "World", salutation: "Hello"}}

    assert GreetingParse.parse(~S(Hi World)) ==
             {:ok, %{greeting_scope: "World", salutation: "Hi"}}
  end
```
Wrap the thing you want to capture in an `as`
Now we have it.  Notice we are discarding the white space as it's not captured with an `as`.

What if we want to allow any number of spaces between the salutation and the scope?
```elixir
    rule :greetings do
      salutation()
      |> repeat(str(" "),1)
      |> as(:greeting_scope, str("World"))
    end

  test "parse greeting" do
    assert GreetingParse.parse(~S(Hi World)) ==
             {:ok, %{greeting_scope: "World", salutation: "Hi"}}

    assert GreetingParse.parse(~S(Hi        World)) ==
             {:ok, %{greeting_scope: "World", salutation: "Hi"}}
  end
```
`repeat(xxx, min_number)` applies the same parser over and over to the remaining text until it fails. If it reached the min_number of appliations the `repeat` parser succeeds.

Say we want to allow any type of white space between the salutation and scope. 
```elixir
    rule :greetings do
      salutation()
      |> repeat(
        one_of(
          str(" "),
          str("\t"),
          str("\n"),
          str("\r")
          ),
        1
      )
      |> as(:greeting_scope, str("World"))
    end
```
This would get annoying fast. There are probably a bunch of characters that I have forgotten to include. 
Luckily there is already a way to define complex string matches. Regex! 
```elixir
    rule :greetings do
      salutation()
      |> repeat(
          match("[\s\r\n]"), 
          1
      )
      |> as(:greeting_scope, str("World"))
    end
```

Sometimes I want to show excitement by including an '!' at the end.
```elixir
    rule :greetings do
      salutation()
      |> repeat(match("[\s\r\n]"),1)
      |> as(:greeting_scope, str("World"))
      |> maybe(str("!"))
    end
```
`maybe` takes a parser. If the parser matches the input stream it will consume the matched characters. Otherwise it will succeed and leave the input stream alone.
There is no change in the output as we are not capturing it, but now "Hi World!" parses.

Let's capture the excitement
```elixir
    rule :greetings do
      salutation()
      |> repeat(match("[\s\r\n]"),1)
      |> as(:greeting_scope, str("World"))
      |> as(:excited, maybe(str("!")))
    end
```

"Hello World" => `{:ok, %{greeting_scope: "World", salutation: "Hi", excited: ""}}`
"Hello World!" => `{:ok, %{greeting_scope: "World", salutation: "Hi", excited: "!"}}`

This is a good example of the difference between Parsing and Transforming.
If we wanted `is_excited` to be a boolean, we would have to parse as above, then do that manipulation in the transform.

The only parser keyword left is `absent?`. This takes a parser and return a parser that fails if the given parser passes.  When `absent?` succeeds, it consumes no text.

So if we wanted to say Hello to anything except "World"
```elixir
    rule :greetings do
      salutation()
      |> repeat(match("[\s\r\n]"),1)
      |> absent?( str("World"))
      |> as(:greeting_scope, match("[a-zA-Z]*"))
      |> as(:excited, maybe(str("!")))
    end
    ...
  test "parse greeting" do
    assert GreetingParse.parse(~S(Hi Sky)) ==
             {:ok, %{greeting_scope: "Sky", salutation: "Hi", excited: ""}}

    assert GreetingParse.parse(~S(Hello        Trees!)) ==
             {:ok, %{greeting_scope: "Trees", salutation: "Hello", excited: "!"}}
  end
```
`absent?` checks the remaining text and ensures it's not a match for it's given parser.

When the input does match `absent?` (and there is not other way for the parser to parse the text) you get an error telling you it failed.
```elixir
assert GreetingParse.parse(~S(Hello        World!)) ==
             {:ok, %{greeting_scope: "World", salutation: "Hello", excited: "!"}}

1) test parse greeting (SimpleMathParserAndTests)
     test/simple_parser_test.exs:28
     Assertion with == failed
     code:  assert GreetingParse.parse(~S"Hello        World!") ==
              {:ok, %{greeting_scope: "World", salutation: "Hello", excited: "!"}}
     left:  {:error, "'World!' does not match absent?(...) "}
     right: {:ok, %{salutation: "Hello", greeting_scope: "World", excited: "!"}}
     stacktrace:
       test/simple_parser_test.exs:35: (test)
```

You know you have understood this concept when this code makes sense..
```elixir
    rule :string do
      str("\"")
      |> as(
        :string,
        repeat(
          as(
            :char,
            one_of([
              absent?(str("\"")) |> absent?(str("\\")) |> match("."),
              str("\\")
              |> as(
                :escaped,
                one_of([
                  match("[\"\\/bfnrt]"),
                  str("u")
                  |> match("[a-fA-F0-9]")
                  |> match("[a-fA-F0-9]")
                  |> match("[a-fA-F0-9]")
                  |> match("[a-fA-F0-9]")
                ])
              )
            ])
          ),
          0
        )
      )
      |> str("\"")
    end
```

## Transformers.

TODO: lets stick a maths expression parser in here and have it do some work for us.
Until then... you can take a look at the XML and JSON parsers in the tests.


## The Magic

`rule`s are just functions!

So... you can define your own functions that can be used in place of rules.

For example: When parsing XML, you could define a function for 'node' that match any open tag, but then only accept a close tag that has the same tag name. This would let you spot these problems in the parser instead of the transformer, giving you a better stack trace and pinpointing the problem in the document early.

TODO: Insert example of this.


# Development

To run the tests.
> mix test

I'm using `mise` to install the version of erlang and elixir I'm using.
> mise install

