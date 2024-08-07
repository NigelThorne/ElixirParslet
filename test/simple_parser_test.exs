defmodule SimpleMathParserAndTests do
  use ExUnit.Case

  defmodule GreetingParse do
    use Parslet

    root(:greetings)

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
      |> repeat(match("[\s\r\n]"), 1)
      |> absent?(str("World"))
      |> as(:greeting_scope, match("[a-zA-Z]*"))
      |> as(:excited, maybe(str("!")))
    end
  end

  test "parse greeting" do
    assert GreetingParse.parse(~S(Hi Sky)) ==
             {:ok, %{greeting_scope: "Sky", salutation: "Hi", excited: ""}}

    assert GreetingParse.parse(~S(Hello        Trees!)) ==
             {:ok, %{greeting_scope: "Trees", salutation: "Hello", excited: "!"}}

    assert GreetingParse.parse(~S(Hello        world!)) ==
             {:ok, %{greeting_scope: "world", salutation: "Hello", excited: "!"}}
  end

  defmodule SimpleMath do
    defmodule Parse do
      use Parslet

      # defines where to start parsing.
      root(:expression)

      rule :expression do
        str("1+1")
      end
    end

    defmodule Transform do
      # default to leaving it untouched
      def transform(any), do: any
    end

    def parse(document) do
      {:ok, parsed} = Parse.parse(document)
      # IO.inspect parsed
      Transformer.transform_with(&Transform.transform/1, parsed)
    end
  end

  @tag timeout: 200

  test "transformed doc" do
    assert SimpleMath.parse(~S(1+1)) == "1+1"
  end
end
