# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    describe BordaVotingHelper do
      let(:election) { create(:election, :ongoing) }
      let(:question) { create(:election_question, :borda, election:, max_choices:, scoring_scale:) }
      let(:max_choices) { 3 }
      let(:scoring_scale) { "start_from_max" }
      let!(:option_a) { create(:election_response_option, question:) }
      let!(:option_b) { create(:election_response_option, question:) }
      let!(:option_c) { create(:election_response_option, question:) }

      describe "#confirm_selected_options" do
        it "returns the ranked options ordered by rank, dropping blanks" do
          buffered = { option_a.id => 1, option_c.id => 2, option_b.id => "" }
          expect(helper.confirm_selected_options(question, buffered)).to eq([option_a, option_c])
        end

        it "returns an empty array when nothing is ranked" do
          expect(helper.confirm_selected_options(question, {})).to eq([])
        end
      end
    end
  end
end
