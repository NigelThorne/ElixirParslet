defmodule ExampleParserTests do
    use ExUnit.Case
    import Transformer
    defmodule JSONParser do
      use Parslet
        rule :value do
          one_of ([
            string(),
            number(),
            object(),
            array(),
            boolean(),
            str("null")
            ])
        end

        rule :boolean do
          as(:boolean, one_of ([
            str("true"),
            str("false"),
          ]))
        end

        rule :string do
            (str("\"")
              |>  as(:string,
                    repeat(
                    as(:char, one_of( [
                        (absent?(str("\"")) |> absent?(str("\\")) |> match(".")),
                        (str("\\")
                            |>  as(:escaped, one_of(
                                [
                                    match("[\"\\/bfnrt]"),
                                    (str("u")
                                        |> match("[a-fA-F0-9]")
                                        |> match("[a-fA-F0-9]")
                                        |> match("[a-fA-F0-9]")
                                        |> match("[a-fA-F0-9]"))
                                ]))
                        )
                    ])),0)
                )
              |> str("\""))

        end

        rule :digit, do: match("[0-9]")

        rule :number do
            as(:number, (maybe(str("-")) |>
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
                )) )
        end

        rule :key_value_pair do
            as(:pair, as(:key, string()) |> str(":") |> as(:value, value()))
        end

        rule :object do
            as(:object, str("{") |>
             maybe(
                 key_value_pair() |> repeat( str(",") |> key_value_pair(), 0)
                 ) |>
            str("}"))
        end

        rule :array do
          as(:array, str("[") |>
             maybe(
                 value() |> repeat( str(",") |> value(), 0)
                 ) |>
          str("]"))
        end

        root :value

    end

    defmodule JSONTransformer do
      def transform(%{escaped: val}) do
        {result, _} = Code.eval_string("\"\\#{val}\"")
        result
      end
      def transform(%{char: val}) do
        val
      end

      def transform(%{string: val}) when is_list(val) do
        List.to_string(val)
        # Enum.join(val,"")
      end
      def transform(%{string: val}) do
        val
      end
      def transform(%{number: val}) do
        {intVal, ""} = Float.parse(val)
        intVal
      end

      def transform(%{object: pairs}) when is_list(pairs) do
        for %{pair: %{key: k, value: v}} <- pairs, into: %{}, do: {k,v}
      end

      def transform(%{object: %{pair: %{key: k, value: v}}}) do
        %{k => v}
      end

      #default to leaving it untouched
      def transform(any) do
        any
      end
    end

    def parseJSON(document) do
      {:ok, parsed} = JSONParser.parse(document)
      #IO.inspect parsed
      Transformer.transform_with(&JSONTransformer.transform/1, parsed)
    end

  @tag timeout: 200
  test "parse json document" do
    assert JSONParser.parse("\" \\nc \"", :string) ==
     {:ok,
             %{
               string: [
                 %{char: " "},
                 %{char: %{escaped: "n"}},
                 %{char: "c"},
                 %{char: " "}
               ]
             }}

    assert JSONParser.parse("\"test\"", :string) ==
      {:ok, %{ string:  [%{char: "t"}, %{char: "e"}, %{char: "s"}, %{char: "t"}]}}

      assert JSONParser.parse("\"\\u26C4\"", :string) ==
      {:ok, %{ string: %{char: %{escaped: "u26C4"}}}}

    assert JSONParser.parse("123", :number) ==
      {:ok, %{number: "123"}}

    assert JSONParser.parse("-102.22e+34", :number) ==
      {:ok, %{number: "-102.22e+34"}}

    assert JSONParser.parse("{}", :object) ==
      {:ok, %{object: "{}"}}
    assert JSONParser.parse("[1,2,3,4]") ==
      {:ok, %{array: [%{number: "1"},%{number: "2"},%{number: "3"},%{number: "4"}]}}
  end

  test "transformed doc" do
    assert parseJSON(~S({"bob":{"jane":234},"fre\r\n\t\u26C4ddy":"a"})) ==
                  %{"bob" => %{"jane" => 234.0},"fre\r\n\t⛄ddy" => "a"}
  end

end
