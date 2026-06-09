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
          let(:votes_buffer) do
            { question.id.to_s => { option_a.id.to_s => "1", option_b.id.to_s => "2", option_c.id.to_s => "3" } }
          end

          controller Decidim::PagesController

          describe "flat render" do
            it "renders one ranked row per selected option in rank order with points" do
              expect(subject).to have_css("div.flex.items-center.gap-2", count: 3)
              expect(subject).to have_css("span.font-semibold", text: "[1]")
              expect(subject).to have_css("span.font-semibold", text: "[2]")
              expect(subject).to have_css("span.font-semibold", text: "[3]")
              expect(subject).to have_css("span.text-gray", text: "3 pts")
              expect(subject).to have_css("span.text-gray", text: "2 pts")
              expect(subject).to have_css("span.text-gray", text: "1 pt")
            end

            it "shows no group subheadings for a flat question" do
              expect(subject).to have_no_css("p.font-semibold")
            end
          end

          describe "grouped render" do
            include_context "with a grouped borda question"

            let!(:option_a) { create(:election_response_option, question:, group_id: group_a_id, body: { "en" => "Cat" }) }
            let!(:option_b) { create(:election_response_option, question:, group_id: group_b_id, body: { "en" => "Oak" }) }
            let(:selected) { [option_a, option_b] }
            let(:votes_buffer) do
              { question.id.to_s => { option_a.id.to_s => "1", option_b.id.to_s => "2" } }
            end

            it "renders group subheadings with their ranked rows" do
              expect(subject).to have_css("p.font-semibold", text: "Animals")
              expect(subject).to have_css("p.font-semibold", text: "Plants")
              expect(subject).to have_css("span.font-semibold", text: "[1]")
              expect(subject).to have_css("span.font-semibold", text: "[2]")
              expect(subject).to have_text("Cat")
              expect(subject).to have_text("Oak")
            end
          end
        end
      end
    end
  end
end
