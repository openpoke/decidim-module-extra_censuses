# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    describe VotingMethodCellHelper do
      let(:election) { create(:election, :ongoing) }

      describe "#voting_method_cell" do
        it "builds the convention cell for a borda question" do
          question = create(:election_question, :borda, election:, max_choices: 3, scoring_scale: "start_from_max")
          expect(helper.voting_method_cell(question, "response_options")).to be_a(Decidim::ExtraCensuses::VotingMethods::Borda::ResponseOptionsCell)
        end

        it "returns nil when the method has no such cell" do
          question = create(:election_question, election:)
          expect(helper.voting_method_cell(question, "response_options")).to be_nil
        end
      end
    end
  end
end
