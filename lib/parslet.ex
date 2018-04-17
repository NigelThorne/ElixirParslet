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
        parser = apply(__MODULE__, @root, [])
        #IO.inspect  parser
        case Parslet.apply_parser(parser, document) do
          {:ok, any, ""}   -> {:ok , any}
          {:ok, any, rest} -> {:error, "Consumed #{inspect(any)}, but had the following remaining '#{rest}'"}
          error -> error
        end
      end
    end
  end

  @type parser_node ::
      {:str, String.t}
    | {:match, String.t}
    | {:repeat, number, parser_node}
    | {:absent?, parser_node}
    | {:sequence, [parser_node]}

  @type unparsed_text :: String.t
  @type parse_tree :: String.t
  @type parsed_document  :: {atom, parse_tree, unparsed_text}
  @type parser_function  :: (unparsed_text -> parsed_document)
  @type matcher_function :: (unparsed_text, parse_tree -> parsed_document)


  ## --- DSL --- ##

  @spec str(String.t)                    :: parser_node
  @spec match(String.t)                  :: parser_node
  @spec repeat(parser_node, number)      :: parser_node
  @spec absent?(parser_node)             :: parser_node

  def str(text), do: {:str, text}
  def match(regex_s), do: {:match, regex_s}
  def repeat(fun, min_count), do: {:repeat, min_count, fun}
  def absent?(fun), do: {:absent?, fun}

  # These functions return a datastructure that represents a parser

  @spec str(parser_node, String.t)                    :: parser_node
  @spec match(parser_node, String.t)                  :: parser_node
  @spec repeat(parser_node, parser_node, number)      :: parser_node
  @spec absent?(parser_node, parser_node)             :: parser_node

  def str(prev, text), do: {:sequence, [prev, str(text)]}
  def match(prev, regex_s), do: {:sequence, [prev, match(regex_s)]}
  def repeat(prev, fun, min_count), do: {:sequence, [prev, repeat(fun, min_count)]}
  def absent?(prev, fun), do: {:sequence, [prev, absent?(fun)]}


  @spec apply_parser(parser_node, unparsed_text, parse_tree)         :: parsed_document

@doc ~S"""
  Takes matches a string against a parser description.

  ## Examples

      iex> Parslet.apply_parser({:str, "test"}, "test", "")
      {:ok, "test", ""}

      iex> Parslet.apply_parser({:repeat, 0, {:str, "a"}}, "", "")
      {:ok, "", ""}

      iex> Parslet.apply_parser({:repeat, 0, {:str, "a"}}, "a", "")
      {:ok, "a", ""}
  """
  def apply_parser(parse_node, document, matched \\ "")

  def apply_parser({:str, text }, document, matched) do
    str_matcher(text, document, matched)
  end

  def apply_parser({:match, regex_s }, document, matched) do
    match_matcher(regex_s, document, matched)
  end

  def apply_parser({:repeat, num, subtree }, document, matched) do
    repeat_matcher(
      fn (doc)->
        apply_parser(subtree, doc)
      end, num, document, matched)
  end

  def apply_parser({:absent?, subtree}, document, matched) do
    absent_matcher(
      fn (doc)->
        apply_parser(subtree, doc)
      end, document, matched)
  end

  def apply_parser({:sequence, [] }, document, matched) do
      {:ok, matched, document}
  end


  def apply_parser({:sequence, [subtree_head | subtree_rest] }, document, matched) do
    case apply_parser(subtree_head, document, matched) do
      {:ok, match, rest} -> apply_parser({:sequence, subtree_rest}, rest, match)
      error -> error
    end
  end

  def apply_parser(error, _, _) do
    error
  end


  @spec absent_matcher(parser_function, unparsed_text, parse_tree) :: parsed_document
  defp absent_matcher(fun, doc, matched) do
    case fun.(doc) do
      {:ok, _, _} ->  {:error, "'#{doc}' does not match absent?(...) "}
      _ -> {:ok, matched, doc}
    end
  end

  @spec str_matcher(String.t, unparsed_text, parse_tree) :: parsed_document
  defp str_matcher(text, doc, matched) do
    tlen = String.length(text)
    if String.starts_with?(doc, text) do
      {:ok, matched <> text,  String.slice(doc, tlen..-1) }
    else
      {:error, "'#{doc}' does not match string '#{text}'"}
    end
  end

  @spec match_matcher(String.t, unparsed_text, parse_tree) :: parsed_document
  defp match_matcher(regex_s, doc, matched) do
    regex = ~r{^#{regex_s}}
    case Regex.run(regex, doc) do
      nil -> {:error, "'#{doc}' does not match regex '#{regex_s}'"}
      [match | _] -> {:ok, matched <> match, String.slice(doc, String.length(match)..-1)}
    end
  end

  @spec repeat_matcher(parser_function, number, unparsed_text, parse_tree) :: parsed_document
  defp repeat_matcher(fun, 0, doc, matched) do
    case fun.(doc) do
      {:ok, match, rest} -> repeat_matcher(fun, 0, rest, matched <> match)
      _ -> {:ok, matched, doc}
    end
  end

  defp repeat_matcher(fun, count, doc, matched) do
    case fun.(doc) do
      {:ok, match, rest} -> repeat_matcher(fun, count - 1, rest, matched <> match)
      other -> other
    end
  end

  @spec identity(unparsed_text) :: parsed_document
  def identity(doc) do
    {:ok, "", doc}
  end

end
