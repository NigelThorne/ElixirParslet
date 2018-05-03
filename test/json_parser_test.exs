defmodule ExampleParserTests do
    use ExUnit.Case
    defmodule JSONParser do
      use Parslet
        rule :value do
          one_of ([
            string(),
            number(),
            object(),
            array(),
            boolean(),
            str("null")
            ])
        end

        rule :boolean do
          as(:boolean, one_of ([
            str("true"),
            str("false"),
          ]))
        end

        rule :sp_ do
          repeat(match("[\s\r\n]"), 0)
        end

        rule :string do
            (str("\"")
              |>  as(:string,
                    repeat(
                    as(:char, one_of( [
                        (absent?(str("\"")) |> absent?(str("\\")) |> match(".")),
                        (str("\\")
                            |>  as(:escaped, one_of(
                                [
                                    match("[\"\\/bfnrt]"),
                                    (str("u")
                                        |> match("[a-fA-F0-9]")
                                        |> match("[a-fA-F0-9]")
                                        |> match("[a-fA-F0-9]")
                                        |> match("[a-fA-F0-9]"))
                                ]))
                        )
                    ])),0)
                )
              |> str("\""))

        end

        rule :digit, do: match("[0-9]")

        rule :number do
            as(:number,
                as(:integer, maybe(str("-")) |>
                  one_of([
                      str("0"),
                      (match("[1-9]") |> repeat( digit(), 0 ))
                  ])) |>
                as(:decimal,
                    maybe(str(".") |> repeat( digit(), 1 ))
                  ) |>
                as(:exponent,
                  maybe(
                    one_of( [str("e"), str("E")] ) |>
                        maybe( one_of( [ str("+"), str("-") ] )) |>
                            repeat( digit(), 1)
                  )
                )
            )
        end

        rule :key_value_pair do
            as(:pair, as(:key, string()) |> sp_() |> str(":") |> sp_() |> as(:value, value()))
        end

        rule :object do
            as(:object, str("{") |> sp_() |>
             maybe(
                 key_value_pair() |>  repeat(  sp_() |> str(",") |> sp_() |> key_value_pair(), 0)
                 ) |> sp_() |>
            str("}"))
        end

        rule :array do
          as(:array, str("[") |> sp_() |>
             maybe(
                 value() |>  repeat( sp_() |> str(",") |> sp_() |> value(), 0)
                 ) |> sp_() |>
          str("]"))
        end

        rule :document do
          sp_() |> value |> sp_()
        end

        root :document

    end

    defmodule JSONTransformer do
      def transform(%{escaped: val}) do
        {result, _} = Code.eval_string("\"\\#{val}\"")
        result
      end

      def transform(%{char: val}) do
        val
      end

      def transform(%{array: val}) do
        val
      end

      def transform(%{string: val}) when is_list(val) do
        List.to_string(val)
      end

      def transform(%{string: val}) do
        val
      end

      def transform(%{boolean: val}) do
        val
      end


      def transform(%{number: %{integer: val, decimal: "", exponent: ""}}) do
         {intVal, ""} = Integer.parse("#{val}")
         intVal
      end

      def transform(%{number: %{integer: val, decimal: dec, exponent: ex}}) do
        {intVal, ""} = Float.parse("#{val}#{dec}#{ex}")
        intVal
      end

      def transform(%{object: pairs}) when is_list(pairs) do
        for %{pair: %{key: k, value: v}} <- pairs, into: %{}, do: {k,v}
      end

      def transform(%{object: %{pair: %{key: k, value: v}}}) do
        %{k => v}
      end

      #default to leaving it untouched
      def transform(any) do

        any
      end
    end


  @tag timeout: 200

  test "sp" do
        assert JSONParser.parse("  ", :sp_) == {:ok, "  "}
  end

  test "number" do
    assert JSONParser.parse("123", :number) == {:ok, %{number: %{decimal: "", exponent: "", integer: "123"}}}


    assert JSONParser.parse("-102.22e+34", :number) ==
      {:ok, %{number: %{decimal: ".22", exponent: "e+34", integer: "-102"}}}

  end

  test "parse json document" do
    assert JSONParser.parse("\" \\nc \"", :string) ==
     {:ok,
             %{
               string: [
                 %{char: " "},
                 %{char: %{escaped: "n"}},
                 %{char: "c"},
                 %{char: " "}
               ]
             }}

    assert JSONParser.parse("\"test\"", :string) ==
      {:ok, %{ string:  [%{char: "t"}, %{char: "e"}, %{char: "s"}, %{char: "t"}]}}

      assert JSONParser.parse("\"\\u26C4\"", :string) ==
      {:ok, %{ string: %{char: %{escaped: "u26C4"}}}}

    assert JSONParser.parse("{}", :object) ==
      {:ok, %{object: "{}"}}

      # assert JSONParser.parse("[1,2,3,4]") ==
      # {:ok, %{array: [%{number: "1"},%{number: "2"},%{number: "3"},%{number: "4"}]}}
  end

      def parseJSON(document) do
      {:ok, parsed} = JSONParser.parse(document)
      #IO.inspect parsed
      Transformer.transform_with(&JSONTransformer.transform/1, parsed)
    end


  test "transformed doc" do
    assert parseJSON(~S({"bob":{"jane":234},"fre\r\n\t\u26C4ddy":"a"})) ==
                  %{"bob" => %{"jane" => 234.0},"fre\r\n\t⛄ddy" => "a"}

    #TODO... handle whitespace.
    IO.inspect parseJSON(~S(
      {"web-app": {
  "servlet": [
    {
      "servlet-name": "cofaxCDS",
      "servlet-class": "org.cofax.cds.CDSServlet",
      "init-param": {
        "configGlossary:installationAt": "Philadelphia, PA",
        "configGlossary:adminEmail": "ksm@pobox.com",
        "configGlossary:poweredBy": "Cofax",
        "configGlossary:poweredByIcon": "/images/cofax.gif",
        "configGlossary:staticPath": "/content/static",
        "templateProcessorClass": "org.cofax.WysiwygTemplate",
        "templateLoaderClass": "org.cofax.FilesTemplateLoader",
        "templatePath": "templates",
        "templateOverridePath": "",
        "defaultListTemplate": "listTemplate.htm",
        "defaultFileTemplate": "articleTemplate.htm",
        "useJSP": false,
        "jspListTemplate": "listTemplate.jsp",
        "jspFileTemplate": "articleTemplate.jsp",
        "cachePackageTagsTrack": -200,
        "cachePackageTagsStore": 200.22,
        "cachePackageTagsRefresh": 60e10,
        "cacheTemplatesTrack": 100,
        "cacheTemplatesStore": 50,
        "cacheTemplatesRefresh": 15,
        "cachePagesTrack": 200,
        "cachePagesStore": 100,
        "cachePagesRefresh": 10,
        "cachePagesDirtyRead": 10,
        "searchEngineListTemplate": "forSearchEnginesList.htm",
        "searchEngineFileTemplate": "forSearchEngines.htm",
        "searchEngineRobotsDb": "WEB-INF/robots.db",
        "useDataStore": true,
        "dataStoreClass": "org.cofax.SqlDataStore",
        "redirectionClass": "org.cofax.SqlRedirection",
        "dataStoreName": "cofax",
        "dataStoreDriver": "com.microsoft.jdbc.sqlserver.SQLServerDriver",
        "dataStoreUrl": "jdbc:microsoft:sqlserver://LOCALHOST:1433;DatabaseName=goon",
        "dataStoreUser": "sa",
        "dataStorePassword": "dataStoreTestQuery",
        "dataStoreTestQuery": "SET NOCOUNT ON;select test='test';",
        "dataStoreLogFile": "/usr/local/tomcat/logs/datastore.log",
        "dataStoreInitConns": 10,
        "dataStoreMaxConns": 100,
        "dataStoreConnUsageLimit": 100,
        "dataStoreLogLevel": "debug",
        "maxUrlLength": 500}},
    {
      "servlet-name": "cofaxEmail",
      "servlet-class": "org.cofax.cds.EmailServlet",
      "init-param": {
      "mailHost": "mail1",
      "mailHostOverride": "mail2"}},
    {
      "servlet-name": "cofaxAdmin",
      "servlet-class": "org.cofax.cds.AdminServlet"},

    {
      "servlet-name": "fileServlet",
      "servlet-class": "org.cofax.cds.FileServlet"},
    {
      "servlet-name": "cofaxTools",
      "servlet-class": "org.cofax.cms.CofaxToolsServlet",
      "init-param": {
        "templatePath": "toolstemplates/",
        "log": 1,
        "logLocation": "/usr/local/tomcat/logs/CofaxTools.log",
        "logMaxSize": "",
        "dataLog": 1,
        "dataLogLocation": "/usr/local/tomcat/logs/dataLog.log",
        "dataLogMaxSize": "",
        "removePageCache": "/content/admin/remove?cache=pages&id=",
        "removeTemplateCache": "/content/admin/remove?cache=templates&id=",
        "fileTransferFolder": "/usr/local/tomcat/webapps/content/fileTransferFolder",
        "lookInContext": 1,
        "adminGroupID": 4,
        "betaServer": true}}],
  "servlet-mapping": {
    "cofaxCDS": "/",
    "cofaxEmail": "/cofaxutil/aemail/*",
    "cofaxAdmin": "/admin/*",
    "fileServlet": "/static/*",
    "cofaxTools": "/tools/*"},

  "taglib": {
    "taglib-uri": "cofax.tld",
    "taglib-location": "/WEB-INF/tlds/cofax.tld"}}}
    )
    )
  end

end
