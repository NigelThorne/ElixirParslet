defmodule ExampleParserTests do
    use ExUnit.Case

    defmodule JSONParser do
    use Parslet
        rule :value do
          one_of ([
            string(),
            number(),
            object(),
            array(),
            str("true"),
            str("false"),
            str("null")
            ])
        end

        rule :string do
            str("\"")
            |>  repeat(
                    one_of( [
                        (absent?(str("\"")) |> absent?(str("\\")) |> match(".")),
                        (str("\\")
                            |>  one_of(
                                [
                                    match("[\"\\/bfnrt]"),
                                    str("u")
                                        |> match("a-fA-F0-9")
                                        |> match("a-fA-F0-9")
                                        |> match("a-fA-F0-9")
                                        |> match("a-fA-F0-9")
                                ])
                        )
                    ]),0)
            |> str("\"")
        end

        rule :digit, do: match("[0-9]")

        rule :number do
            maybe(str("-")) |>
            one_of([
                str("0"),
                (match("[1-9]") |> repeat( digit(), 0 ))
                ]) |>
            maybe(
                    str(".") |> repeat( digit(), 1 )
                ) |>
            maybe(
                    one_of( [str("e"), str("E")] ) |>
                        maybe( one_of( [ str("+"), str("-") ] )) |>
                            repeat( digit(), 1)
                )
        end

        rule :key_value_pair do
            string() |> str(":") |> value()
        end

        rule :object do
            str("{") |>
             maybe(
                 key_value_pair() |> repeat( str(",") |> key_value_pair(), 0)
                 ) |>
            str("}")
        end

        rule :array do
          str("[") |>
             maybe(
                 value() |> repeat( str(",") |> value(), 0)
                 ) |>
          str("]")
        end

        root :value
    end

  @tag timeout: 200
  test "parse json document" do
    assert JSONParser.parse("\"test\"", :string) == {:ok, "\"test\""}
    assert JSONParser.parse("123", :number) == {:ok, "123"}
    assert JSONParser.parse("-102.22e+34", :number) == {:ok, "-102.22e+34"}
    assert JSONParser.parse("{}", :object) == {:ok, "{}"}
    assert JSONParser.parse("{\"bob\":111,\"jane\":234}", :object) == {:ok, "{\"bob\":111,\"jane\":234}"}
    assert JSONParser.parse("{\"bob\":{\"jane\":234}}", :object) == {:ok, "{\"bob\":{\"jane\":234}}"}
    assert JSONParser.parse("{\"bob\":{\"jane\":234}}") == {:ok, "{\"bob\":{\"jane\":234}}"}
    assert JSONParser.parse("[1,2,3,4]") == {:ok, "[1,2,3,4]"}
  end
end
