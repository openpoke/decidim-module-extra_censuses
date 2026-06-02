# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    describe AdminQuestionMetaHelper do
      let(:election) { create(:election, :ongoing) }

      def grouped_settings(*titles)
        {
          "grouped" => true,
          "groups" => titles.each_with_index.map do |title, index|
            { "id" => "g#{index}", "title" => { "en" => title }, "position" => index }
          end
        }
      end

      describe "#question_meta_chips" do
        context "with an approval question and no constraints" do
          let(:question) { create(:election_question, election:, question_type: "multiple_option") }

          it "returns no chips" do
            expect(helper.question_meta_chips(question)).to eq([])
          end
        end

        context "with a single_option question" do
          let(:question) { create(:election_question, election:, question_type: "single_option") }

          it "returns no chips" do
            expect(helper.question_meta_chips(question)).to eq([])
          end
        end

        context "with an approval question and max_choices only" do
          let(:question) { create(:election_question, election:, question_type: "multiple_option", max_choices: 3) }

          it "returns the up-to choices chip" do
            expect(helper.question_meta_chips(question)).to eq(["Choose up to 3"])
          end
        end

        context "with an approval question and min + max choices" do
          let(:question) { create(:election_question, election:, question_type: "multiple_option", min_choices: 1, max_choices: 5) }

          it "returns the range choices chip" do
            expect(helper.question_meta_chips(question)).to eq(["Choose 1–5"])
          end
        end

        context "with a grouped approval question" do
          let(:question) { create(:election_question, election:, question_type: "multiple_option", settings: grouped_settings("A", "B")) }

          it "does not add a chip for grouping" do
            expect(helper.question_meta_chips(question)).to eq([])
          end
        end

        context "with a borda question (start_from_max, grouped)" do
          let(:question) do
            create(:election_question, :borda, election:, max_choices: 5,
                                               settings: { "voting_method" => "borda",
                                                           "scoring_scale" => "start_from_max" }.merge(grouped_settings("A", "B")))
          end

          it "returns chips in order: scoring, choices" do
            expect(helper.question_meta_chips(question)).to eq(
              ["Standard Borda count", "Choose 1–5"]
            )
          end
        end

        context "with a borda question (start_from_min)" do
          let(:question) { create(:election_question, :borda, election:, max_choices: 5, scoring_scale: "start_from_min") }

          it "uses the start_from_min scoring text" do
            expect(helper.question_meta_chips(question)).to include("Modified Borda count")
          end
        end
      end
    end
  end
end
