defmodule ParsletV1 do
  @moduledoc """
  Documentation for Parslet.
  """

  # Callback invoked by `use`.
  #
  # For now it returns a quoted expression that
  # imports the module itself into the user code.
  @doc false
  defmacro __using__(_opts) do
    quote do
      import Parslet

      # Initialize @tests to an empty list
      @rules []
      @root :undefined

      # Invoke Parslet.__before_compile__/1 before the module is compiled
      @before_compile Parslet
    end
  end

  @doc """
  Defines a test case with the given description.

  ## Examples

      rule :testString do
        str("test")
      end

  """
  defmacro rule(description, do: block) do
    function_name = description
    quote do
      # Prepend the newly defined test to the list of rules
      @rules [unquote(function_name) | @rules]
      def unquote(function_name)(), do: unquote(block)
    end
  end

  defmacro root(rule_name) do
    quote do
      # Prepend the newly defined test to the list of rules
      @root unquote(rule_name)
    end
  end


  # This will be invoked right before the target module is compiled
  # giving us the perfect opportunity to inject the `parse/1` function
  @doc false
  defmacro __before_compile__(_env) do
    quote do
      def parse(document) do
        # IO.puts "Root is defined as #{@root}"
        # Enum.each @rules, fn name ->
        #   IO.puts "Defined rule #{name}"
        # end
        case apply(__MODULE__, @root, []).(document) do
          {:ok, any, ""} -> {:ok , any}
          {:ok, any, rest} -> {:error, "Consumed #{inspect(any)}, but had the following remaining '#{rest}'"}
          error -> error
        end
      end
    end
  end

  def call_aux(fun, aux) do
    fn doc ->
      case fun.(doc) do
        {:ok, match, rest} -> aux.(rest, match)
        other -> other
      end
    end
  end


  def str(text), do: str(&Parslet.identity/1, text)
  def match(regex_s), do: match(&Parslet.identity/1, regex_s)
  def repeat(fun, min_count), do: repeat(&Parslet.identity/1, min_count, fun)
  def absent?(fun), do: absent?(&Parslet.identity/1, fun)

  def str(fun, text), do: call_aux( fun,
      fn (doc, matched) -> str_aux(text, doc, matched) end )
  def match(fun, regex_s), do: call_aux( fun,
      fn (doc, matched) -> match_aux(regex_s, doc, matched) end )
  def repeat(prev, min_count, fun), do: call_aux( prev,
      fn (doc, matched) -> repeat_aux(fun, min_count, doc, matched) end )
  def absent?(prev, fun), do: call_aux( prev,
      fn (doc, matched) -> absent_aux(fun, doc, matched) end )

  defp absent_aux(fun, doc, matched) do
    case fun.(doc) do
      {:ok, _, _} ->  {:error, "'#{doc}' does not match absent?(...) "}
      _ -> {:ok, matched, doc}
    end
  end

  defp str_aux(text, doc, matched) do
      tlen = String.length(text)
      if String.starts_with?(doc, text) do
        {:ok, matched <> text,  String.slice(doc, tlen..-1) }
      else
        {:error, "'#{doc}' does not match string '#{text}'"}
      end
  end

  defp match_aux(regex_s, doc, matched) do
    regex = ~r{^#{regex_s}}
    case Regex.run(regex, doc) do
      nil -> {:error, "'#{doc}' does not match regex '#{regex_s}'"}
      [match | _] -> {:ok, matched <> match, String.slice(doc, String.length(match)..-1)}
    end
  end

  defp repeat_aux(fun, 0, doc, matched) do
    case fun.(doc) do
      {:ok, match, rest} -> repeat_aux(fun, 0, rest, matched <> match)
      _ -> {:ok, matched, doc}
    end
  end

  defp repeat_aux(fun, count, doc, matched) do
    case fun.(doc) do
      {:ok, match, rest} -> repeat_aux(fun, count - 1, rest, matched <> match)
      other -> other
    end
  end

  def identity(doc) do
    {:ok, "", doc}
  end

end
