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
    assert ParsletExample.parse("test") == {:ok, {:str, "test"}}
  end
  test "str doesnt match different strings" do
    assert ParsletExample.parse("tost") == {:error, "'tost' does not match string 'test'"}
  end
  test "parse reports error if not all the input document is consumed" do
    assert ParsletExample.parse("test_the_best") == {:error, "Consumed {:str, \"test\"}, but had the following remaining '_the_best'"}
  end

  defmodule ParsletExample2 do
    use Parslet

    rule :test_regex do
      reg("123")
    end

    # calling another rule should just work. :)
    rule :document do
      test_regex()
    end

    root :document
  end

  test "regex" do
    assert ParsletExample2.parse("123") == {:ok, {:reg, "123"}}
    assert ParsletExample2.parse("w123") == {:error, "'w123' does not match regex '123'"}
    assert ParsletExample2.parse("234") == {:error, "'234' does not match regex '123'"}
    assert ParsletExample2.parse("123the_rest") == {:error, "Consumed {:reg, \"123\"}, but had the following remaining 'the_rest'"}
  end

end
