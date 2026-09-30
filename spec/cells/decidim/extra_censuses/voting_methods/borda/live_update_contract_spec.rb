# frozen_string_literal: true

require "spec_helper"

# Pins the live-update seam: every data-* hook the poller rewrites must be
# server-rendered with exactly the value the presenter payload carries for it,
# otherwise the first poll visibly rewrites the page with a different format.
module Decidim
  module ExtraCensuses
    describe "Borda live update contract", type: :cell do
      subject { cell("decidim/extra_censuses/voting_methods/borda/results", question, context: {}).call(:show) }

      let(:election) { create(:election, :published_results) }
      let(:question) { create(:election_question, :borda, election:, max_choices: 3) }
      let!(:option_a) { create(:election_response_option, question:) }
      let!(:option_b) { create(:election_response_option, question:) }
      let(:question_hash) { election.presenter.to_json(admin: false)[:questions].find { |hash| hash[:id] == question.id } }

      controller Decidim::PagesController

      before do
        create(:election_vote, question:, response_option: option_a, voter_uid: "v1", position: 1)
        create(:election_vote, question:, response_option: option_b, voter_uid: "v1", position: 2)
      end

      def payload_option(option_id)
        question_hash[:response_options].find { |hash| hash[:id] == option_id }
      end

      it "server-renders every option score hook with the exact payload value" do
        nodes = subject.all("[data-option-result-score-text]")
        expect(nodes.size).to eq(2)

        nodes.each do |node|
          option_hash = payload_option(node["data-option-result-score-text"].split(",").last.to_i)
          expect(option_hash).to have_key(:result_score_text)
          expect(node.text.strip).to eq(option_hash[:result_score_text])
        end
      end

      it "server-renders every option percent hook with the exact payload value" do
        nodes = subject.all("[data-option-result-score-percent-text]")
        expect(nodes.size).to eq(2)

        nodes.each do |node|
          option_hash = payload_option(node["data-option-result-score-percent-text"].split(",").last.to_i)
          expect(option_hash).to have_key(:result_score_percent_text)
          expect(node.text.strip).to eq(option_hash[:result_score_percent_text])
        end
      end

      it "server-renders the total hook with the exact payload value" do
        expect(question_hash).to have_key(:result_score_total_text)
        expect(subject.find("[data-question-total-score-text]").text.strip).to eq(question_hash[:result_score_total_text])
      end

      it "exposes the numeric score key the poller uses for bar widths" do
        expect(subject).to have_css("[data-option-result-score-width]", count: 2)
        expect(payload_option(option_a.id)[:result_score]).to be_a(Integer)
        expect(payload_option(option_b.id)[:result_score]).to be_a(Integer)
      end
    end
  end
end
