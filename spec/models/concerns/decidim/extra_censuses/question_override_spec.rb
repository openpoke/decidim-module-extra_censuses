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

      describe "#voting_method" do
        context "when settings has no voting_method key" do
          let(:settings) { {} }

          it "defaults to 'approval'" do
            expect(question.voting_method).to eq("approval")
          end
        end

        context "when settings has voting_method set" do
          let(:question) { create(:election_question, election:, settings:, max_choices: 3, question_type: "multiple_option") }
          let(:settings) { { "voting_method" => "borda" } }

          it "returns the stored value" do
            expect(question.voting_method).to eq("borda")
          end
        end
      end

      describe "#scoring_scale" do
        context "when settings has no scoring_scale key" do
          let(:settings) { {} }

          it "defaults to 'start_from_max'" do
            expect(question.scoring_scale).to eq("start_from_max")
          end
        end

        context "when settings has scoring_scale set" do
          let(:settings) { { "scoring_scale" => "start_from_min" } }

          it "returns the stored value" do
            expect(question.scoring_scale).to eq("start_from_min")
          end
        end
      end

      describe "#allows_borda?" do
        let(:settings) { {} }

        context "when question_type is multiple_option" do
          let(:question) { create(:election_question, election:, settings:, question_type: "multiple_option") }

          it "is true" do
            expect(question.allows_borda?).to be true
          end
        end

        context "when question_type is single_option" do
          let(:question) { create(:election_question, election:, settings:, question_type: "single_option") }

          it "is false" do
            expect(question.allows_borda?).to be false
          end
        end
      end

      describe "model-level validations" do
        let(:question) { build(:election_question, election:, settings:, question_type: "multiple_option", max_choices: 3) }

        context "when voting_method is invalid" do
          let(:settings) { { "voting_method" => "ranked_pairs" } }

          it "is invalid" do
            expect(question).not_to be_valid
            expect(question.errors[:voting_method]).to include("is invalid")
          end
        end

        context "when scoring_scale is invalid" do
          let(:settings) { { "scoring_scale" => "exotic" } }

          it "is invalid" do
            expect(question).not_to be_valid
            expect(question.errors[:scoring_scale]).to include("is invalid")
          end
        end

        context "when borda is enabled without max_choices" do
          let(:question) { build(:election_question, election:, settings: { "voting_method" => "borda" }, question_type: "multiple_option", max_choices: nil) }

          it "is invalid" do
            expect(question).not_to be_valid
            expect(question.errors[:voting_method]).to be_present
          end
        end

        context "when borda is enabled with max_choices = 1" do
          let(:question) { build(:election_question, election:, settings: { "voting_method" => "borda" }, question_type: "multiple_option", max_choices: 1) }

          it "is invalid" do
            expect(question).not_to be_valid
            expect(question.errors[:voting_method]).to be_present
          end
        end

        context "when borda is enabled with a single_option question" do
          let(:question) { build(:election_question, election:, settings: { "voting_method" => "borda" }, question_type: "single_option", max_choices: 3) }

          it "is invalid" do
            expect(question).not_to be_valid
            expect(question.errors[:voting_method]).to be_present
          end
        end

        context "when borda is enabled with multiple_option and max_choices > 1" do
          let(:question) { build(:election_question, election:, settings: { "voting_method" => "borda" }, question_type: "multiple_option", max_choices: 3) }

          it "is valid" do
            expect(question).to be_valid
          end
        end
      end
    end
  end
end
