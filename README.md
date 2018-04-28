# Parslet

A port of Ruby's [Parslet](https://github.com/kschiess/parslet/) library to Erlang

# Done

I have something similar to Parslet's "Parser" classes working. 
I have a JSON parser working (without whitespace) as a proof of completeness. 

# Missing

Parslet has a concept of Transformers. These take your parsed structure and using a depth first approach allow you to apply transformations from leaves to the top of the tree. This lets you split your parsing problem into "collect all the data from the file" then "translate it to a format I want to consume". 

This approach is what I love about Parslet, so would not be a complete solution  without it. 

The error handling is woeful. To be of use, this parser needs to pass around line numbers etc from the source document so you know at what point in your document and grammer the parser failed. This is something that Parslet does quite well. 

# Future 

Primarily I am working on this to learn Elixir. In that endevor I want to make a version of this parser that uses GenServer and Actors to create a Parser Application from your code, so you can dispatch documents to it to parse. I forsee rules each build an actor, so the document gets passed around and gradually consumed.

Something that is missing from the original ... is the ability to run the parser in several modes.
One mode is the production parser.. which just parses the document to data, so you can transform it, and should be really fast..
Another is for grammer development ... the feedback should be around where the parser failed.. not where text was wrong... and it should detect endless loops in your grammer.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `parslet` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:parslet, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/parslet](https://hexdocs.pm/parslet).

