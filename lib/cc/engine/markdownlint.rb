require "json"
require "shellwords"
require "posix/spawn"

module CC
  module Engine
    class Markdownlint
      def initialize(root, engine_config, io)
        @root = root
        @engine_config = engine_config
        @io = io
        @contents = {}
      end

      def run
        pid, _, out, err = POSIX::Spawn.popen4("mdl #{include_paths}")
        out.each_line do |line|
          io.print JSON.dump(issue(line))
          io.print "\0"
        end
      ensure
        STDERR.print err.read
        [out, err].each(&:close)

        Process::waitpid(pid)
      end

      private

      attr_reader :root, :engine_config, :io, :contents

      def include_paths
        return root unless engine_config.has_key?("include_paths")

        markdown_files = engine_config["include_paths"].select do |path|
          path.end_with?(".md")
        end

        Shellwords.join(markdown_files)
      end

      def issue(line)
        match_data = line.match(/(?<filename>[^:]*):(?<line>\d+): (?<code>MD\d+) (?<description>.*)/)
        line = match_data[:line].to_i
        filename = match_data[:filename].sub(root + "/", "")
        content = content(match_data[:code])

        {
          categories: ["Style"],
          check_name: match_data[:code],
          content: {
            body: content,
          },
          description: match_data[:description],
          location: {
            begin: line,
            end: line,
            path: filename,
          },
          type: "issue",
          remediation_points: 50_000,
          severity: "info",
        }
      end

      def content(code)
        contents.fetch(code) do
          filename = "../../../contents/#{code}.md"
          path = File.expand_path(filename, File.dirname(__FILE__))
          content = File.read(path)

          contents[code] = content
        end
      end
    end
  end
end
