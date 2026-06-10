# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    module VotingMethods
      module Borda
        describe QuestionValidator do
          subject(:validator) { described_class.new }

          let(:election) { create(:election) }

          describe "#validate" do
            context "when the question is a valid borda question" do
              let(:question) { build(:election_question, election:, settings: { "voting_method" => "borda" }, question_type: "multiple_option", max_choices: 3) }

              it "adds no errors" do
                validator.validate(question)
                expect(question.errors[:voting_method]).to be_empty
              end
            end

            context "when borda has no max_choices" do
              let(:question) { build(:election_question, election:, settings: { "voting_method" => "borda" }, question_type: "multiple_option", max_choices: nil) }

              it "adds an error on :voting_method" do
                validator.validate(question)
                expect(question.errors[:voting_method]).to include("is invalid")
              end
            end

            context "when borda has max_choices = 1" do
              let(:question) { build(:election_question, election:, settings: { "voting_method" => "borda" }, question_type: "multiple_option", max_choices: 1) }

              it "adds an error on :voting_method" do
                validator.validate(question)
                expect(question.errors[:voting_method]).to include("is invalid")
              end
            end

            context "when borda is set on a single_option question" do
              let(:question) { build(:election_question, election:, settings: { "voting_method" => "borda" }, question_type: "single_option", max_choices: 3) }

              it "adds an error on :voting_method" do
                validator.validate(question)
                expect(question.errors[:voting_method]).to include("is invalid")
              end
            end

            context "when both max_choices and question_type are wrong" do
              let(:question) { build(:election_question, election:, settings: { "voting_method" => "borda" }, question_type: "single_option", max_choices: nil) }

              it "adds a single error" do
                validator.validate(question)
                expect(question.errors[:voting_method]).to eq(["is invalid"])
              end
            end

            context "when the question is not borda" do
              let(:question) { build(:election_question, election:, settings: {}, question_type: "single_option", max_choices: nil) }

              it "adds no errors" do
                validator.validate(question)
                expect(question.errors[:voting_method]).to be_empty
              end
            end
          end
        end
      end
    end
  end
end
