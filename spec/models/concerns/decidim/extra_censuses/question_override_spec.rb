# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    describe QuestionOverride do
      let(:election) { create(:election) }
      let(:question) { create(:election_question, election:, settings:) }

      describe "#grouped?" do
        context "when settings[grouped] is true" do
          let(:settings) { { "grouped" => true } }

          it "returns true" do
            expect(question.grouped?).to be true
          end
        end

        context "when settings[grouped] is false" do
          let(:settings) { { "grouped" => false } }

          it "returns false" do
            expect(question.grouped?).to be false
          end
        end

        context "when settings[grouped] is missing" do
          let(:settings) { {} }

          it "returns false" do
            expect(question.grouped?).to be false
          end
        end

        context "when settings[grouped] is nil" do
          let(:settings) { { "grouped" => nil } }

          it "returns false" do
            expect(question.grouped?).to be false
          end
        end
      end

      describe "#groups" do
        context "when settings has no groups key" do
          let(:settings) { { "grouped" => true } }

          it "returns an empty array" do
            expect(question.groups).to eq([])
          end
        end

        context "when settings has groups stored out of order" do
          let(:settings) do
            {
              "grouped" => true,
              "groups" => [
                { "id" => "b", "title" => { "en" => "Second" }, "position" => 1 },
                { "id" => "a", "title" => { "en" => "First" }, "position" => 0 }
              ]
            }
          end

          it "returns ResponseOptionGroup instances sorted by position" do
            groups = question.groups
            expect(groups.map(&:class)).to all(eq(Decidim::ExtraCensuses::ResponseOptionGroup))
            expect(groups.map(&:id)).to eq(%w(a b))
            expect(groups.map(&:position)).to eq([0, 1])
          end
        end

        context "when a group has no position key" do
          let(:settings) do
            {
              "grouped" => true,
              "groups" => [{ "id" => "x", "title" => { "en" => "X" } }]
            }
          end

          it "defaults the missing position to 0" do
            expect(question.groups.first.position).to eq(0)
          end
        end
      end
    end
  end
end
