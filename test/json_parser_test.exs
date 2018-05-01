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
            as(:string, (str("\"")
            |>  as(:string_body, repeat(
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
                    ]),0))
            |> str("\"")))
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

  def transform(%{string_body: val}), do: val
  def transform(%{string: val}), do: val
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

  def transform_tree(map) when is_map(map) do
      # take each pair, transform_tree the value, generate a new map from it.
      # then transform the map.
      transform(for {k, v} <- map, into: %{}, do: {k, transform_tree(v)})
  end

  def transform_tree(list) when is_list(list) do
      # transform_tree each value generate a new list from it.
      # then transform the list
      transform(Enum.map(list, &transform_tree/1))
  end

  # default to transfroming the value
  def transform_tree(value) do
    transform(value)
  end

  @tag timeout: 200
  test "parse json document" do
    assert JSONParser.parse("\"test\"", :string) ==
      {:ok, %{ string: %{string_body: "test"}}}

    assert JSONParser.parse("123", :number) ==
      {:ok, %{number: "123"}}

    assert JSONParser.parse("-102.22e+34", :number) ==
      {:ok, %{number: "-102.22e+34"}}

    assert JSONParser.parse("{}", :object) ==
      {:ok, %{object: "{}"}}

    assert JSONParser.parse("{\"bob\":111,\"jane\":234}", :object) ==
      {:ok,
             %{
               object: [
                 %{
                   pair: %{
                     key: %{string: %{string_body: "bob"}},
                     value: %{number: "111"}
                   }
                 },
                 %{
                   pair: %{
                     key: %{string: %{string_body: "jane"}},
                     value: %{number: "234"}
                   }
                 }
               ]
             }
            }

    assert JSONParser.parse("{\"bob\":{\"jane\":234}}", :object) ==
      {:ok,
        %{
          object: %{
            pair: %{
              key: %{string: %{string_body: "bob"}},
              value: %{
                object: %{
                  pair: %{
                    key: %{string: %{string_body: "jane"}},
                    value: %{number: "234"}
                  }
                }
              }
            }
          }
        }}


    assert JSONParser.parse("{\"bob\":{\"jane\":234}}") ==
      {:ok,
        %{
          object: %{
            pair: %{
              key: %{string: %{string_body: "bob"}},
              value: %{
                object: %{
                  pair: %{
                    key: %{string: %{string_body: "jane"}},
                    value: %{number: "234"}
                  }
                }
              }
            }
          }
        }}

    assert JSONParser.parse("[1,2,3,4]") ==
      {:ok, %{array: [%{number: "1"},%{number: "2"},%{number: "3"},%{number: "4"}]}}
  end

  test "transformed doc" do
    {:ok, parsed} = JSONParser.parse("{\"bob\":{\"jane\":234},\"freddy\":\"a\"}")
    assert transform_tree(parsed) ==
      %{"bob" => %{"jane" => 234},"freddy" => "a"}
  end

end
