require "open-uri"
require "mdl/version"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)
task default: :spec

class Content
  def initialize(code = nil)
    @code = code
    @body = ""
  end

  def <<(line)
    body << line
  end

  def write
    if code
      IO.write(filename, body.strip)
    end
  end

  private

  attr_reader :code, :body

  def filename
    File.expand_path("contents/#{code}.md", File.dirname(__FILE__))
  end
end

namespace :docs do
  task :scrape do
    rules = open("https://raw.githubusercontent.com/mivok/markdownlint/v#{MarkdownLint::VERSION}/docs/RULES.md")
    content = Content.new

    rules.each_line do |line|
      if line.start_with?("## MD")
        content.write
        content = Content.new(line[/(MD\d+)/])
      end

      content << line
    end
  end
end
