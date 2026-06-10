# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    module VotingMethods
      module Borda
        describe ConfirmCell, type: :cell do
          subject { cell(cell_path, question, context:).call(state) }

          let(:cell_path) { "decidim/extra_censuses/voting_methods/borda/confirm" }
          let(:state) { :show }
          let(:context) { { selected:, votes_buffer:, voter_uid: nil } }
          let(:election) { create(:election, :ongoing) }
          let(:question) { create(:election_question, :borda, election:, max_choices: 3, scoring_scale: "start_from_max") }
          let!(:option_a) { create(:election_response_option, question:) }
          let!(:option_b) { create(:election_response_option, question:) }
          let!(:option_c) { create(:election_response_option, question:) }
          let(:selected) { [option_a, option_b, option_c] }
          let(:votes_buffer) { { question.id.to_s => { option_a.id.to_s => "1", option_b.id.to_s => "2", option_c.id.to_s => "3" } } }

          controller Decidim::PagesController

          describe "flat render" do
            it "renders one ranked row per selected option in rank order with points" do
              expect(subject).to have_content("[1]")
              expect(subject).to have_content("[2]")
              expect(subject).to have_content("[3]")
              expect(subject).to have_content("3 pts")
              expect(subject).to have_content("2 pts")
              expect(subject).to have_content("1 pt")
            end
          end

          describe "grouped render" do
            include_context "with a grouped borda question"

            let!(:option_a) { create(:election_response_option, question:, group_id: group_a_id, body: { "en" => "Cat" }) }
            let!(:option_b) { create(:election_response_option, question:, group_id: group_b_id, body: { "en" => "Oak" }) }
            let(:selected) { [option_a, option_b] }
            let(:votes_buffer) { { question.id.to_s => { option_a.id.to_s => "1", option_b.id.to_s => "2" } } }

            it "renders group subheadings with their ranked rows" do
              expect(subject).to have_content("Animals")
              expect(subject).to have_content("Plants")
              expect(subject).to have_content("[1]")
              expect(subject).to have_content("[2]")
              expect(subject).to have_content("Cat")
              expect(subject).to have_content("Oak")
            end
          end
        end
      end
    end
  end
end
