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
      def unquote(function_name)(prev), do: {:sequence, [prev, unquote(function_name)()]}
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
      def parse(document, rule \\ @root) do
        # IO.puts "Root is defined as #{@root}"
        # Enum.each @rules, fn name ->
        #   IO.puts "Defined rule #{name}"
        # end
        parser = apply(__MODULE__, rule, [])
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
  @type parse_tree ::
    String.t
    | {atom, parse_tree}
  @type parsed_document  :: {atom, parse_tree, unparsed_text}
  @type parser_function  :: (unparsed_text -> parsed_document)
  @type matcher_function :: (unparsed_text, parse_tree -> parsed_document)

  ## --- DSL --- ##

  @spec str(String.t)                    :: parser_node
  @spec match(String.t)                  :: parser_node
  @spec repeat(parser_node, number)      :: parser_node
  @spec absent?(parser_node)             :: parser_node
  @spec as(atom, parser_node)            :: parser_node

  def str(text), do: {:str, text}
  def match(regex_s), do: {:match, regex_s}
  def repeat(fun, min_count), do: {:repeat, min_count, fun}
  def absent?(fun), do: {:absent?, fun}
  def as(name, fun), do: {:as, name, fun}

  # These functions return a datastructure that represents a parser

  @spec str(parser_node, String.t)                    :: parser_node
  @spec match(parser_node, String.t)                  :: parser_node
  @spec repeat(parser_node, parser_node, number)      :: parser_node
  @spec absent?(parser_node, parser_node)             :: parser_node
  @spec as(parser_node, atom, parser_node)            :: parser_node

  def str(prev, text), do: {:sequence, [prev, str(text)]}
  def match(prev, regex_s), do: {:sequence, [prev, match(regex_s)]}
  def repeat(prev, fun, min_count), do: {:sequence, [prev, repeat(fun, min_count)]}
  def absent?(prev, fun), do: {:sequence, [prev, absent?(fun)]}
  def as(prev, name, fun), do: {:sequence, [prev, as(name, fun)]}

@doc ~S"""
  Takes matches a string against a parser description.

  ## Examples

      iex> Parslet.apply_parser({:str, "test"}, "test")
      {:ok, "test", ""}

      iex> Parslet.apply_parser({:repeat, 0, {:str, "a"}}, "")
      {:ok, "", ""}

      iex> Parslet.apply_parser({:repeat, 0, {:str, "a"}}, "a")
      {:ok, "a", ""}

      iex> Parslet.apply_parser({:as, :nigel, {:str, "a"}}, "a")
      {:ok, %{:nigel => "a"}, ""}

      iex> Parslet.apply_parser({:sequence, [{:as, :nigel, {:str, "test"}}, {:str, "bob"}]}, "testbob")
      {:ok, %{:nigel => "test"},""}

      iex> Parslet.apply_parser({:sequence, [{:as, :a, {:str, "x"}}, {:as, :b, {:str, "y"}}]}, "xy")
      {:ok, %{:a => "x", :b =>  "y"},""}


  """
  @spec apply_parser(parser_node, unparsed_text, parse_tree)   :: parsed_document
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

  def apply_parser({:as, name, subtree }, document, matched) do
    case apply_parser(subtree, document) do
      {:ok, match, rest} -> {:ok, build_parse_tree(matched, %{name => match}), rest}
      error -> error
    end
  end

  def apply_parser(error, _, _) do
    error
  end


  #  If we only have strings, concatenate them.
  #  If we have a map, keep it
  #  If we have two maps, merge them
  defp build_parse_tree(map, rmap) when is_map(map) and is_map(rmap), do: Map.merge(map,rmap)
  defp build_parse_tree(map, _) when is_map(map),  do: map
  defp build_parse_tree(_, map) when is_map(map),  do: map
  defp build_parse_tree(ltree, rtree) when is_binary(ltree) and is_binary(rtree), do: ltree <> rtree

  defp build_parse_list(map1, map2) when is_map(map1) and is_map(map2), do: [map1 , map2]
  defp build_parse_list(ltree, rtree) when is_list(ltree), do: ltree + rtree
  defp build_parse_list("", any), do: any
  defp build_parse_list(ltree, rtree) when is_binary(ltree) and is_binary(rtree), do: ltree <> rtree

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
      {:ok, build_parse_tree(matched , text),  String.slice(doc, tlen..-1) }
    else
      {:error, "'#{doc}' does not match string '#{text}'"}
    end
  end

  @spec match_matcher(String.t, unparsed_text, parse_tree) :: parsed_document
  defp match_matcher(regex_s, doc, matched) do
    regex = ~r{^#{regex_s}}
    case Regex.run(regex, doc) do
      nil -> {:error, "'#{doc}' does not match regex '#{regex_s}'"}
      [match | _] -> {:ok, build_parse_tree(matched, match), String.slice(doc, String.length(match)..-1)}
    end
  end

  @spec repeat_matcher(parser_function, number, unparsed_text, parse_tree) :: parsed_document
  defp repeat_matcher(fun, 0, doc, matched) do
    case fun.(doc) do
      {:ok, match, rest} -> repeat_matcher(fun, 0, rest, build_parse_list( matched, match))
      _ -> {:ok, matched, doc}
    end
  end

  defp repeat_matcher(fun, count, doc, matched) do
    case fun.(doc) do
      {:ok, match, rest} -> repeat_matcher(fun, count - 1, rest, build_parse_list( matched, match))
      other -> other
    end
  end

  @spec identity(unparsed_text) :: parsed_document
  def identity(doc) do
    {:ok, "", doc}
  end

end
