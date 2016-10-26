require "digest/md5"
require "json"
require "posix/spawn"

module CC
  module Engine
    class Markdownlint
      CONFIG_FILE = "./.mdlrc".freeze
      EXTENSIONS = %w[.markdown .md].freeze

      def initialize(root, engine_config, io, err_io)
        @root = root
        @engine_config = engine_config
        @io = io
        @err_io = err_io
        @contents = {}
      end

      def run
        return if include_paths.length == 0

        child = POSIX::Spawn::Child.new("mdl", *mdl_options, *include_paths)

        out = child.out.force_encoding("UTF-8")
        err = child.err.force_encoding("UTF-8")
        if err.chars.any?
          err_io.puts(err)
        end

        out.each_line do |line|
          io.print JSON.dump(issue(line))
          io.print "\0"
        end
      end

      private

      attr_reader :root, :engine_config, :err_io, :io, :contents

      def include_paths
        return [root] unless engine_config.has_key?("include_paths")

        @include_paths ||= engine_config["include_paths"].select do |path|
          EXTENSIONS.include?(File.extname(path)) || path.end_with?("/")
        end
      end

      def mdl_options
        options = ["--no-warnings"]
        options << "--config" << CONFIG_FILE if File.exist?(CONFIG_FILE)
        options
      end

      def issue(line)
        match_data = line.match(/(?<path>[^:]*):(?<line_number>\d+): (?<code>MD\d+) (?<description>.*)/)
        line_number = match_data[:line_number].to_i
        path = match_data[:path]
        relative_path = File.absolute_path(path).sub(root + "/", "")
        check_name = match_data[:code]
        body = content(check_name)

        issue = {
          categories: ["Style"],
          check_name: check_name,
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
        issue[:content] = { body: body } if body
        issue
      end

      def content(code)
        contents.fetch(code) do
          filename = "../../../contents/#{code}.md"
          path = File.expand_path(filename, File.dirname(__FILE__))

          if File.exist?(path)
            content = File.read(path)
            contents[code] = content
          end
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
