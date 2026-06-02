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

      describe "#borda_points" do
        it "delegates to Question#borda_points" do
          expect(helper.borda_points(question, 1, 3)).to eq(question.borda_points(1, 3))
          expect(helper.borda_points(question, 2, 3)).to eq(question.borda_points(2, 3))
        end
      end

      # The label is "%{ordinal} place (%{count} point[s])"; the point value is
      # the only thing inside the parentheses, so match that fragment to avoid a
      # collision with the ordinal digits.
      def points_in(label)
        label[/\((\d+) point/, 1]&.to_i
      end

      describe "#borda_position_label" do
        context "with start_from_max scoring" do
          let(:scoring_scale) { "start_from_max" }

          it "embeds the point value from Question#borda_points" do
            (1..max_choices).each do |position|
              label = helper.borda_position_label(question, position, max_choices)
              expect(points_in(label)).to eq(question.borda_points(position, max_choices))
            end
          end
        end

        context "with start_from_min scoring" do
          let(:scoring_scale) { "start_from_min" }
          let(:ballot_size) { 2 }

          it "embeds the point value from Question#borda_points for the given ballot size" do
            (1..ballot_size).each do |position|
              label = helper.borda_position_label(question, position, ballot_size)
              expect(points_in(label)).to eq(question.borda_points(position, ballot_size))
            end
          end
        end
      end

      describe "#borda_position_options" do
        it "labels each option with the point value derived from Question#borda_points" do
          options = helper.borda_position_options(question)
          options.each do |label, position|
            expect(points_in(label)).to eq(question.borda_points(position, question.max_votable_options))
          end
        end
      end
    end
  end
end
