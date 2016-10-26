require "spec_helper"
require "json"
require "cc/engine/markdownlint"

module CC
  module Engine
    describe Markdownlint do
      describe "#run" do
        it "returns issues for markdownlint output" do
          io = StringIO.new
          path = File.expand_path("../../fixtures/default", File.dirname(__FILE__))
          CC::Engine::Markdownlint.new(path, {}, io, STDERR).run
          issues = io.string.split("\0")
          issue = JSON.parse(issues.first)

          expect(issue["type"]).to eq("issue")
          expect(issue["categories"]).to eq(["Style"])
          expect(issue["remediation_points"]).to eq(50_000)
          expect(issue["description"]).to eq("Header levels should only increment by one level at a time")
          expect(issue["check_name"]).to eq("MD001")
          expect(issue["content"]["body"]).to include("This rule is triggered when you skip header levels in a markdown document")
          expect(issue["location"]["path"]).to eq("FIXTURE.md")
          expect(issue["location"]["lines"]["begin"]).to eq(3)
          expect(issue["location"]["lines"]["end"]).to eq(3)
        end

        it "exits cleanly when the underlying tool has an error" do
          io = StringIO.new
          err_io = StringIO.new
          path = File.expand_path("../../fixtures/default", File.dirname(__FILE__))

          child = double(out: "", err: "Some error output")
          expect(POSIX::Spawn::Child).to receive(:new).and_return(child)
          CC::Engine::Markdownlint.new(path, {}, io, err_io).run

          expect(err_io.string).to eq("Some error output\n")
        end

        it "tolerates files with colons in the names" do
          io = StringIO.new
          path = File.expand_path("../../fixtures/with_colons", File.dirname(__FILE__))
          CC::Engine::Markdownlint.new(path, {}, io, STDERR).run
          issues = io.string.split("\0")
          issue = JSON.parse(issues.first)
          expect(issue["check_name"]).to eq("MD001")
        end

        it "exits cleanly when the underlying tool outputs an unexpected format" do
          io = StringIO.new
          path = File.expand_path("../../fixtures/default", File.dirname(__FILE__))

          child = double(out: "weird output", err: "")
          expect(POSIX::Spawn::Child).to receive(:new).and_return(child)
          expect {
            CC::Engine::Markdownlint.new(path, {}, io, STDERR).run
          }.to raise_error(CC::Engine::Markdownlint::UnexpectedOutputFormat)
        end

        it "exits cleanly with empty include_paths" do
          io = StringIO.new
          path = File.expand_path("../../fixtures/default", File.dirname(__FILE__))
          CC::Engine::Markdownlint.new(path, {"include_paths" => []}, io, STDERR).run
          expect(io.string.strip.length).to eq(0)
        end

        it "returns issue when config supplies include_paths" do
          io = StringIO.new
          path = File.expand_path("../../fixtures/default", File.dirname(__FILE__))

          Dir.chdir(path) do
            CC::Engine::Markdownlint.new(path, {"include_paths" => ["./"]}, io, STDERR).run
            issues = io.string.split("\0")
            issue = JSON.parse(issues.first)

            expect(issue["type"]).to eq("issue")
            expect(issue["categories"]).to eq(["Style"])
            expect(issue["remediation_points"]).to eq(50_000)
            expect(issue["description"]).to eq("Header levels should only increment by one level at a time")
            expect(issue["check_name"]).to eq("MD001")
            expect(issue["content"]["body"]).to include("This rule is triggered when you skip header levels in a markdown document")
            expect(issue["location"]["path"]).to eq("FIXTURE.md")
            expect(issue["location"]["lines"]["begin"]).to eq(3)
            expect(issue["location"]["lines"]["end"]).to eq(3)
          end
        end

        it "returns a unique fingerprint per issue" do
          io = StringIO.new
          path = File.expand_path("../../fixtures/default", File.dirname(__FILE__))
          Dir.chdir(path) do
            CC::Engine::Markdownlint.new(path, {"include_paths" => ["./"]}, io, STDERR).run
            issues = io.string.split("\0")

            expect(issues.length).to eq 2

            issue_1 = JSON.parse(issues[0])
            issue_2 = JSON.parse(issues[1])

            expect(issue_1["fingerprint"]).not_to eq issue_2["fingerprint"]
          end
        end

        it "uses the .mdlrc configuration file if one exists" do
          io = StringIO.new
          path = File.expand_path("../../fixtures/with_config", File.dirname(__FILE__))

          # Fixture contains a configuration file which disables MD001 and a
          # Markdown file which violates MD001
          Dir.chdir(path) do
            CC::Engine::Markdownlint.new(path, {"include_paths" => ["./"]}, io, STDERR).run
            expect(io.string.split("\0")).to be_empty
          end
        end
      end
    end
  end
end
