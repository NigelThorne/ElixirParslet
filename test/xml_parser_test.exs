defmodule ExampleXmlParserTests do
  use ExUnit.Case

  defmodule SimpleXML do
    defmodule XmlParser do
      use Parslet

      rule :text do
        as(:text, repeat(match("[^<]"), 1))
      end

      rule :tag_name do
        as(:tag_name, repeat(match("[a-zA-Z0-9_\-]"), 1))
      end

      rule :tag do
        as(
          :tag,
          as(:otag, str("<") |> tag_name |> str(">"))
          |> as(:content, element())
          |> as(:ctag, str("</") |> tag_name |> str(">"))
        )
      end

      rule :element do
        one_of([
          tag(),
          text(),
          str("")
        ])
      end

      root(:element)
    end

    defmodule XmlTransformer do
      # default to leaving it untouched
      def transform(%{text: val}), do: val
      def transform(%{tag_name: val}), do: val
      def transform(%{element: val}), do: val

      def transform(%{otag: otag, content: val, ctag: ctag}) do
        if(otag === ctag) do
          %{tag: otag, content: val}
        else
          throw("tags don't match")
        end
      end

      def transform(%{tag: val}), do: val

      def transform(any) do
        any
      end
    end

    def parseXML(document) do
      {:ok, parsed} = XmlParser.parse(document)
      # IO.inspect parsed
      Transformer.transform_with(&XmlTransformer.transform/1, parsed)
    end
  end

  @tag timeout: 200

  test "transformed doc" do
    assert SimpleXML.parseXML(~S(<test>example</test>)) ==
             %{tag: "test", content: "example"}
  end
end
