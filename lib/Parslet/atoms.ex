# defmodule Parslet.Atoms do
#   @doc """
#   Atoms are all methods that make the low level parser concepts.
#   They should be methods give you back a function that
#     takes a doc and returns you a {:ok, parsed_node, unparsed_text} or {:error, message}
#   """
#   @type unparsed_text :: String.t()
#   @type parsed_node ::
#           {:str, String.t()}
#           | {:match, String.t()}
#           | {:repeat, number, parsed_node}
#           | {:absent?, parsed_node}
#           | {:sequence, [parsed_node]}
#           | {:options, [parsed_node]}
#           | {:maybe, parsed_node}
#           | {:as, atom, parsed_node}

#   @type parse_tree ::
#           String.t()
#           | parsed_node

#   @type parser_output ::
#           {:ok, parsed_node, unparsed_text}
#           | {:error, String.t()}

#   @type parser_function :: (unparsed_text -> parser_output)

#   @spec identity_parser() :: parser_function
#   @spec str_parser(String.t()) :: parser_function
#   @spec match_parser(String.t()) :: parser_function
#   @spec absent?_parser(parser_function) :: parser_function
#   @spec sequence_parser([parser_function]) :: parser_function
#   @spec options_parser([parser_function]) :: parser_function
#   @spec maybe_parser(parser_function) :: parser_function
#   @spec as_parser(parser_function) :: parser_function
#   @spec repeat_parser(number) :: parser_function

#   def identity_parser() do
#     fn doc -> identity(doc) end
#   end
#   def identity(doc), do: {:ok, "", doc}

#   def str(text) do
#     fn doc ->
#       tlen = String.length(text)

#       if String.starts_with?(doc, text) do
#         {:ok, text, String.slice(doc, tlen..-1)}
#       else
#         {:error, "'#{doc}' does not match string '#{text}'"}
#       end
#     end
#   end

#   def match(regex_s) do
#     fn doc ->
#       regex = ~r{^#{regex_s}}

#       case Regex.run(regex, doc) do
#         nil ->
#           {:error, "'#{doc}' does not match regex '#{regex_s}'"}

#         [match | _] ->
#           {:ok, match, String.slice(doc, String.length(match)..-1)}
#       end
#     end
#   end

#   def absent?(parser) do
#     fn doc ->
#       case parser.(doc) do
#         {:ok, _, _} -> {:error, "'#{doc}' does not match absent?(...) "}
#         _ -> {:ok, "", doc}
#       end
#     end
#   end

#   def sequence(parser) do
#     fn doc ->
#       case parser.(doc) do
#         {:ok, _, _} -> {:error, "'#{doc}' does not match absent?(...) "}
#         _ -> {:ok, "", doc}
#       end
#     end
#   end

# end
