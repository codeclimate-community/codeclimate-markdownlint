require "spec_helper"
require "json"
require "cc/engine/markdownlint"

module CC
  module Engine
    describe Markdownlint do
      describe "#run" do
        it "returns issues for markdownlint output" do
          io = StringIO.new
          path = File.expand_path("../../fixtures", File.dirname(__FILE__))
          CC::Engine::Markdownlint.new(path, {}, io).run
          issues = io.string.split("\0")
          issue = JSON.parse(issues.first)

          expect(issue["type"]).to eq("issue")
          expect(issue["categories"]).to eq(["Style"])
          expect(issue["remediation_points"]).to eq(50_000)
          expect(issue["description"]).to eq("Header levels should only increment by one level at a time")
          expect(issue["check_name"]).to eq("MD001")
          expect(issue["content"]["body"]).to include("This rule is triggered when you skip header levels in a markdown document")
          expect(issue["location"]["path"]).to eq("FIXTURE.md")
          expect(issue["location"]["begin"]).to eq(3)
          expect(issue["location"]["end"]).to eq(3)
        end
      end
    end
  end
end
