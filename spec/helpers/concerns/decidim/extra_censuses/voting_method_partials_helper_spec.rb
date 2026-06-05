# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    describe VotingMethodPartialsHelper do
      let(:election) { create(:election, :ongoing) }

      describe "#voting_method_partial" do
        it "resolves the convention path for a borda question" do
          question = create(:election_question, :borda, election:, max_choices: 3, scoring_scale: "start_from_max")
          expect(helper.voting_method_partial(question, "response_options")).to eq("decidim/extra_censuses/voting_methods/borda/response_options")
        end

        it "returns nil when the method has no such partial" do
          question = create(:election_question, election:)
          expect(helper.voting_method_partial(question, "response_options")).to be_nil
        end
      end
    end
  end
end
