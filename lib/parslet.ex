defmodule Parslet do
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

  ## TODO: Add root command to define root symbol
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


  # TODO ... checkout ("a" <> rest ) syntax...
  # https://stackoverflow.com/questions/25896762/how-can-pattern-matching-be-done-on-text
  def str text do
    tlen = String.length(text)
    fn doc ->
      if String.starts_with? doc, text do
        {:ok, {:str, text}, String.slice(doc, tlen..-1)}
      else
        {:error, "'#{doc}' does not match string '#{text}'"}
      end
    end
  end

  def reg(regex_s) do
    regex = ~r{^#{regex_s}}
    fn doc ->
      case Regex.run(regex, doc) do
        nil -> {:error, "'#{doc}' does not match regex '#{regex_s}'"}
        [match | _] -> {:ok, {:reg, match}, String.slice(doc, String.length(match)..-1)}
      end
    end
  end

end
