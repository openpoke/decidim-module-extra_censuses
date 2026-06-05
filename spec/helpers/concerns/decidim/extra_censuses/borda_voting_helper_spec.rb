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

      describe "#borda_confirm_rows" do
        before do
          allow(helper).to receive(:votes_buffer).and_return(
            question.id.to_s => { option_a.id.to_s => "2", option_b.id.to_s => "1" }
          )
          allow(helper).to receive(:voter_uid).and_return(nil)
        end

        it "yields [option, rank, points] sorted by rank" do
          rows = helper.borda_confirm_rows(question, [option_a, option_b], 2)
          expect(rows.map { |option, rank, _points| [option, rank] }).to eq([[option_b, 1], [option_a, 2]])
          expect(rows.map { |_option, _rank, points| points }).to eq(
            [question.borda_points(1, 2), question.borda_points(2, 2)]
          )
        end
      end
    end
  end
end
