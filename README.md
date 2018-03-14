# Parslet

A port of Ruby's [Parslet](https://github.com/kschiess/parslet/) library to Erlang

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

Initially I am just recreating the parslet parser.

Something that is missing from the original ... is the ability to run the parser in several modes.
One mode is the production parser.. which just parses the document to data, so you can transform it, and should be really fast..
Another is for grammer development ... the feedback should be around where the parser failed.. not where text was wrong... and it should detect endless loops in your grammer.

