defmodule ParsletTest do
  use ExUnit.Case
  doctest Parslet


  defmodule ParsletExample do
    use Parslet

    rule :test_string do
      str("test")
    end
    root :test_string
  end

  test "str matches whole string" do
    assert ParsletExample.parse("test") == {:ok, "test"}
  end
  test "str doesnt match different strings" do
    assert ParsletExample.parse("tost") == {:error, "'tost' does not match string 'test'"}
  end
  test "parse reports error if not all the input document is consumed" do
    assert ParsletExample.parse("test_the_best") ==
      {:error, "Consumed \"test\", but had the following remaining '_the_best'"}
  end

  defmodule ParsletExample2 do
    use Parslet

    rule :test_regex do
      match("123")
    end

    # calling another rule should just work. :)
    rule :document do
      test_regex()
    end

    root :document
  end

  test "[123]" do
    assert ParsletExample2.parse("123") == {:ok, "123"}
    assert ParsletExample2.parse("w123") == {:error, "'w123' does not match regex '123'"}
    assert ParsletExample2.parse("234") == {:error, "'234' does not match regex '123'"}
    assert ParsletExample2.parse("123the_rest") == {:error, "Consumed \"123\", but had the following remaining 'the_rest'"}
  end


  defmodule ParsletExample3 do
    use Parslet

    rule :a do
      repeat(str("a"),1)
    end

    root :a
  end

  test "a+" do
    assert ParsletExample3.parse("a") == {:ok, "a"}
    assert ParsletExample3.parse("aaaaaa") == {:ok, "aaaaaa"}
  end

  defmodule ParsletExample4 do
    use Parslet

    rule :a do
      str("a") |> str("b")
    end

    root :a
  end

  test "a > b = ab" do
    assert ParsletExample4.parse("ab") == {:ok, "ab"}
  end

  defmodule ParsletExample5 do
    use Parslet

    rule :a do
      repeat(str("a") |>  str("b"), 1)
    end

    root :a
  end

  test "(a > b)+" do
    assert ParsletExample5.parse("ababab") == {:ok, "ababab"}
  end

   defmodule ParsletExample6 do
    use Parslet

    rule :a do
      str("a") |> repeat(str("b"), 1)
    end

    root :a
  end

  test "a > b+" do
    assert ParsletExample6.parse("abbbbb") == {:ok, "abbbbb"}
  end

  defmodule ParsletExample7 do
    use Parslet

    rule :quoted_string do
      str("\"") |> as(:string, repeat( absent?(str("\"")) |> match("."), 1)) |> str("\"")
    end

    rule :x do
      as(:_x, str("x"))
    end

    rule :yx do
     as(:_yx, str("y") |> x() )
   end

    root :quoted_string
  end

  test "absent?" do
    assert ParsletExample7.parse("\"This is a string\"") == {:ok, %{:string => "This is a string"}}
  end

  test "as a in as b in as c" do
    assert ParsletExample7.parse("yx", :yx) == {:ok, %{:_yx => %{:_x => "x"}}}
  end
end
