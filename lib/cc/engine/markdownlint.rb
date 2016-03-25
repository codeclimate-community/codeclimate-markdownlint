require "json"
require "shellwords"
require "posix/spawn"
require "digest/md5"

module CC
  module Engine
    class Markdownlint
      EXTENSIONS = %w[.markdown .md].freeze

      def initialize(root, engine_config, io)
        @root = root
        @engine_config = engine_config
        @io = io
        @contents = {}
      end

      def run
        return if include_paths.strip.length == 0
        run_mdl
      end

      private

      attr_reader :root, :engine_config, :io, :contents

      def run_mdl
        pid, _, out, err = POSIX::Spawn.popen4("mdl --no-warnings #{include_paths}")
        out.each_line do |line|
          io.print JSON.dump(issue(line))
          io.print "\0"
        end
      ensure
        STDERR.print err.read
        [out, err].each(&:close)

        Process::waitpid(pid)
      end

      def include_paths
        return root unless engine_config.has_key?("include_paths")

        markdown_files = engine_config["include_paths"].select do |path|
          EXTENSIONS.include?(File.extname(path)) || path.end_with?("/")
        end

        Shellwords.join(markdown_files)
      end

      def issue(line)
        match_data = line.match(/(?<path>[^:]*):(?<line_number>\d+): (?<code>MD\d+) (?<description>.*)/)
        line_number = match_data[:line_number].to_i
        path = match_data[:path]
        relative_path = File.absolute_path(path).sub(root + "/", "")
        content = content(match_data[:code])
        check_name = match_data[:code]

        {
          categories: ["Style"],
          check_name: check_name,
          content: {
            body: content,
          },
          description: match_data[:description],
          fingerprint: fingerprint(check_name, path, line_number),
          location: {
            lines: {
              begin: line_number,
              end: line_number,
            },
            path: relative_path,
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

      def fingerprint(check_name, path, line_number)
        md5 = Digest::MD5.new
        md5 << check_name
        md5 << path
        md5 << read_line(path, line_number).gsub(/\s/, "")
        md5.hexdigest
      end

      def read_line(path, line_number_to_read)
        File.open(path) do |file|
          file.each_line.with_index do |line, current_line_number|
            return line if current_line_number == line_number_to_read - 1
          end
        end

        ""
      end
    end
  end
end
