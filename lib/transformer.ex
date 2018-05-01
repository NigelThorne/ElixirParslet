defmodule Transformer do
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
      import Transformer

      # Initialize @rules to an empty list
      @rules %{}

      # Invoke Transformer.__before_compile__/1 before the module is compiled
      @before_compile Transformer
    end
  end

  @doc """
  Defines a test case with the given description.

  ## Examples

      rule(:string => simple(:x)) do
        StringLiteral.new(x)
      end

  """
  defmacro rule(description, do: block) do
    function_name = description
    aux_function_name = String.to_atom("_#{description}")
    code = quote do
      # Prepend the newly defined test to the list of rules
      def unquote(aux_function_name)(), do: unquote(block)
      def unquote(function_name)(), do: {:call_rule, __MODULE__, unquote(function_name)}
      def unquote(function_name)(prev), do: {:sequence, [prev, unquote(function_name)()]}
    end
    #IO.puts Macro.to_string(code)
    code
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      def apply(document) do
        # Depth first transformation.

        # IO.inspect  parser
        case Transformer.apply(parser, document) do
          {:ok, any, ""}   -> {:ok , any}
          {:ok, any, rest} -> {:error, "Consumed #{inspect(any)}, but had the following remaining '#{rest}'"}
          error -> error
        end
      end
    end
  end




end
