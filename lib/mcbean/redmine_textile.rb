require 'redcloth'

class McBean
  attr_writer :__redmine_textile__ # :nodoc:

  @@__formats__ << "redmine_textile"

  ##
  #  Create a McBean from a Textile document string (or IO object)
  #
  def McBean.redmine_textile(string_or_io)
    mcbean = new
    mcbean.__redmine_textile__ = McBean::Textilify::Antidote.new(string_or_io.respond_to?(:read) ? string_or_io.read : string_or_io)
    mcbean
  end

  ##
  #  Generate a Textile string representation of the McBeaned document.
  #
  #  So you can convert documents in other formats to Textile as follows:
  #
  #    McBean.fragment(File.read(path_to_html_file)).to_textile
  #
  def to_redmine_textile
    __redmine_textile__.to_s
  end

  def __redmine_textile__(generate_from_html_if_necessary = true) # :nodoc:
    @__textile__ ||= nil
    if @__textile__.nil? && generate_from_html_if_necessary
      @__textile__ = McBean::RedmineTextilify::Antidote.new(
                       Loofah::Helpers.remove_extraneous_whitespace(
                         __html__.dup.scrub!(:escape).scrub!(RedmineTextilify.new).text(:encode_special_chars => false)
                     ))
    end
    @__textile__
  end

  # :stopdoc:
  class RedmineTextilify < Loofah::Scrubber
    Antidote = ::RedCloth::TextileDoc

    def initialize
      @direction = :bottom_up
      @link_references = nil
      @link_reference_count = 0
    end

    def scrub(node)
      return CONTINUE if node.text?
      replacement_killer = \
        case node.name
        when "h1"
          new_text node, "\nh1. #{node.content}\n"
        when "h2"
          new_text node, "\nh2. #{node.content}\n"
        when "h3"
          new_text node, "\nh3. #{node.content}\n"
        when "h4"
          new_text node, "\nh4. #{node.content}\n"
        when "blockquote"
          new_text node, "\nbq. #{node.content.gsub(/\n\n/, "\n").sub(/^\n/,'')}"
        when "li"
          nil # handled by parent list tag
        when "ul"
          fragment = []
          node.xpath("./li").each do |li|
            fragment << "* #{li.text}" if li.text =~ /\S/
          end
          new_text node, "\n#{fragment.join("\n")}\n"
        when "ol"
          fragment = []
          node.xpath("./li").each do |li|
            fragment << "# #{li.text}" if li.text =~ /\S/
          end
          new_text node, "\n#{fragment.join("\n")}\n"
        when "code"
          if node.parent.name == "pre"
            new_text node, "\n<pre><code class=\"#{node[:class]}\">#{node.content}</code></pre>"
          else
            nil
          end
        when "br"
          new_text node, "\n"
        when "a"
          if node['href'].nil?
            new_text node, node.content
          elsif node['title']
            new_text node, %Q{["#{node.text} (#{node['title']})":#{node['href']}]}
          else
            new_text node, %Q{["#{node.text}":#{node['href']}]}
          end
        else
          if Loofah::Elements::BLOCK_LEVEL.include?(node.name)
            new_text node, "\n#{node.content}\n"
          else
            nil
          end
        end
      node.replace(replacement_killer) if replacement_killer
    end

    private

    def new_text(node, text)
      Nokogiri::XML::Text.new(text, node.document)
    end
  end
  # :startdoc:
end
