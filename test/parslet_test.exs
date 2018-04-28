defmodule ParsletTest do
  use ExUnit.Case
  doctest Parslet

  defmodule Parser do
    use Parslet

    rule :test_string do
      str("test")
    end

   rule :test_regex do
      match("123")
    end

    rule :aplus do
      repeat(str("a"),1)
    end

    rule :ab do
      str("a") |> str("b")
    end

    rule :abab do
      repeat(str("a") |>  str("b"), 1)
    end

    rule :a_bplus do
      str("a") |> repeat(str("b"), 1)
    end

    rule :quot, do: str("\"")

    rule :quoted_string do
      quot() |> as(:string, repeat( absent?(quot()) |> match("."), 1)) |> str("\"")
    end

    rule :x, do: as(:_x, str("x"))
    rule :yx, do: as(:_yx, str("y") |> x )
    rule :repeated_x, do: repeat(x(), 2)

    rule :x_or_y, do: one_of [str("x"), str("y")]

    root :test_string
  end

  test "parse defaults to root rule" do
    assert Parser.parse("test") == {:ok, "test"}
  end

  test "str matches whole string" do
    assert Parser.parse("test", :test_string) == {:ok, "test"}
  end

  test "str doesnt match different strings" do
    assert Parser.parse("tost", :test_string) == {:error, "'tost' does not match string 'test'"}
  end

  test "parse reports error if not all the input document is consumed" do
    assert Parser.parse("test_the_best", :test_string) ==
      {:error, "Consumed \"test\", but had the following remaining '_the_best'"}
  end

  test "regex [123]" do
    assert Parser.parse("123", :test_regex) == {:ok, "123"}
    assert Parser.parse("w123", :test_regex) == {:error, "'w123' does not match regex '123'"}
    assert Parser.parse("234", :test_regex) == {:error, "'234' does not match regex '123'"}
    assert Parser.parse("123the_rest", :test_regex) == {:error, "Consumed \"123\", but had the following remaining 'the_rest'"}
  end

  test "repeat a+" do
    assert Parser.parse("a",:aplus) == {:ok, "a"}
    assert Parser.parse("aaaaaa",:aplus) == {:ok, "aaaaaa"}
    assert Parser.parse("", :aplus) == {:error, "'' does not match string 'a'"}
  end

  test "sequence a > b = ab" do
    assert Parser.parse("ab", :ab) == {:ok, "ab"}
  end

  test "repeat sequence (a > b)+" do
    assert Parser.parse("ababab", :abab) == {:ok, "ababab"}
  end

  test "repeat in sequence a > b+" do
    assert Parser.parse("ab", :a_bplus) == {:ok, "ab"}
    assert Parser.parse("abb", :a_bplus) == {:ok, "abb"}
    assert Parser.parse("abbc", :a_bplus) == {:error, "Consumed \"abb\", but had the following remaining 'c'"}
  end

  test "absent?" do
    assert Parser.parse("\"This is a string\"", :quoted_string) == {:ok, %{:string => "This is a string"}}
  end

  test "as in an as" do
    assert Parser.parse("yx", :yx) == {:ok, %{:_yx => %{:_x => "x"}}}
  end

  test "repeated as in an as" do

    assert Parser.parse("xx", :repeated_x) == {:ok, [%{:_x => "x"}, %{:_x => "x"}]}
  end

  test "options " do
    assert Parser.parse("x", :x_or_y) == {:ok, "x"}
    assert Parser.parse("y", :x_or_y) == {:ok, "y"}
  end

end
