require File.dirname(__FILE__) + "/helper"

class TestMcBeanMarkdown < Test::Unit::TestCase
  context McBean::Markdownify do
    context "#to_markdown" do
      should "add whitespace around block elements" do
        assert_markdown "before<div>inner</div>after", "before\ninner\nafter", false
      end

      should "convert h1 tag" do
        assert_markdown "<h1>Foo</h1>", "\nFoo\n==========\n"
      end

      should "convert h2 tag" do
        assert_markdown "<h2>Foo</h2>", "\nFoo\n----------\n"
      end

      should "convert h3 tag" do
        assert_markdown "<h3>Foo</h3>", "\n### Foo ###\n"
      end

      should "convert h4 tag" do
        assert_markdown "<h4>Foo</h4>", "\n#### Foo ####\n"
      end

      should "convert blockquote tag" do
        assert_markdown "<blockquote><p>Hello\nGoodbye</p></blockquote>",
        "> Hello\n> Goodbye\n"
      end

      #     should "convert nested blockquote tag" do
      #       assert_markdown(
      #         "<blockquote><p>Hello</p>\n\n<blockquote><p>Nested</p></blockquote>\n\n<p>Goodbye</p></blockquote>",
      # <<-EOM
      # > Hello
      # >
      # > > Nested
      # >
      # > Goodbye
      # EOM
      #         )
      #     end

      should "convert unordered list" do
        assert_markdown "<ul>\n<li>one</li>\n<li>two</li>\n<li>three</li>\n</ul>\n",
        "\n* one\n* two\n* three\n"
      end

      should "convert ordered list" do
        assert_markdown "<ol>\n<li>one</li>\n<li>two</li>\n<li>three</li>\n</ol>\n",
        "\n1. one\n2. two\n3. three\n"
      end

      should "ignore empty unordered list items" do
        assert_markdown "<ul>\n<li>one</li>\n<li></li>\n<li>three</li>\n</ul>\n",
        "\n* one\n* three\n",
        false
      end

      should "ignore empty ordered list items" do
        assert_markdown "<ol>\n<li>one</li>\n<li></li>\n<li>three</li>\n</ol>\n",
        "\n1. one\n3. three\n",
        false
      end

      should "convert code blocks" do
        assert_markdown "<pre><code>This is a code block\ncontinued\n</code></pre>",
        "\n    This is a code block\n    continued\n\n"
      end

      should "convert <br> tags to newlines" do
        assert_markdown "<div>hello<br>there</div>",
        "\nhello\nthere\n",
        false
        assert_markdown "<div>hello<br />there</div>",
        "\nhello\nthere\n",
        false
      end

      context "anchors" do
        should "convert <a> tags" do
          assert_markdown "<p>Yes, magic helmet. And <a href=\"http://sample.com/\">I'll give you a sample</a>.</p>",
          "\nYes, magic helmet. And [I'll give you a sample](http://sample.com/).\n"
        end

        context "<a> tags without hrefs" do
          should "be ignored" do
            assert_markdown "<div><a name='link-target'>target title</a></div>",
            "\ntarget title\n",
            false

            assert_markdown "<div><a id='link-target'>target title</a></div>",
            "\ntarget title\n",
            false
          end
        end

        context "<a> tags with titles" do
          should "convert fq urls to reference-style" do
            assert_markdown2 "<p>Yes, magic helmet. And <a href=\"http://sample.com/\" title=\"Fudd\">I'll give you a sample</a>.</p>",
            "\nYes, magic helmet. And [I'll give you a sample][1].\n\n[1]: http://sample.com/ \"Fudd\"\n"
          end

          should "convert relative urls to reference-style" do
            assert_markdown2 "<p>Yes, magic helmet. And <a href=\"/home\" title=\"Fudd\">I'll give you a sample</a>.</p>",
            "\nYes, magic helmet. And [I'll give you a sample][1].\n\n[1]: /home \"Fudd\"\n"
          end

          should "convert multiple to appear in order at the end of the document" do
            assert_markdown2 "<p>See <a href=\"/prefs\" title=\"Prefs\">Prefs</a> and <a href=\"/home\" title=\"Home\">Home</a>.</p>",
            "\nSee [Prefs][1] and [Home][2].\n\n[1]: /prefs \"Prefs\"\n[2]: /home \"Home\"\n"
          end
        end
      end
    end
  end

  context McBean::Markdownify::Antidote do
    context "given that RDiscount is already pretty well tested" do
      context "let's limit ourselves to a token test case" do
        should "convert markdown into html" do
          assert_equal "<h1>hello</h1>\n", McBean.markdown("hello\n=====\n").to_html
        end
      end
    end
  end

  private

  def assert_markdown html, markdown, roundtrip=true
    assert_equal(html, McBean::Markdownify::Antidote.new(markdown).to_html.chomp, "markdown roundtrip failed") if roundtrip
    assert_equal(markdown, McBean.fragment(html).to_markdown, "fragment transformation failed")
    assert_equal(Loofah::Helpers.remove_extraneous_whitespace("\n#{markdown}\n"),
      McBean.document("<div>#{html}</div>").to_markdown, "document transformation failed")
  end

  def assert_markdown2 html, markdown, roundtrip=true
    # note peskily absent newline at end of document. sigh.
    assert_equal(html, McBean::Markdownify::Antidote.new(markdown).to_html.chomp, "markdown roundtrip failed") if roundtrip
    assert_equal(markdown, McBean.fragment(html).to_markdown, "fragment transformation failed")
    assert_equal(Loofah::Helpers.remove_extraneous_whitespace("\n#{markdown}"),
      McBean.document("<div>#{html}</div>").to_markdown, "document transformation failed")
  end
end
