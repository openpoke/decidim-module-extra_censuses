# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    module VotingMethods
      module Borda
        describe ResultsCell, type: :cell do
          subject { cell(cell_path, question, context: {}).call(:show) }

          let(:cell_path) { "decidim/extra_censuses/voting_methods/borda/results" }
          let(:election) { create(:election, :published_results) }
          let(:question) do
            create(:election_question, :borda, election:, max_choices: 3, body: { "en" => "Rank these" })
          end
          let!(:option_a) { create(:election_response_option, question:, body: { "en" => "Alpha" }) }
          let!(:option_b) { create(:election_response_option, question:, body: { "en" => "Beta" }) }
          let!(:option_c) { create(:election_response_option, question:, body: { "en" => "Gamma" }) }

          controller Decidim::PagesController

          # A=6, B=4, C=1 (total 11) ; votes A=2 B=2 C=1 (total 5)
          before do
            create(:election_vote, question:, response_option: option_a, voter_uid: "v1", position: 1)
            create(:election_vote, question:, response_option: option_b, voter_uid: "v1", position: 2)
            create(:election_vote, question:, response_option: option_c, voter_uid: "v1", position: 3)
            create(:election_vote, question:, response_option: option_a, voter_uid: "v2", position: 1)
            create(:election_vote, question:, response_option: option_b, voter_uid: "v2", position: 2)
          end

          describe "per-option rendering" do
            it "sizes each bar by its share of the total points, not the max" do
              expect(subject).to have_css(".percent-bar-width[style*='width: 54.5%']")
              expect(subject).to have_css(".percent-bar-width[style*='width: 36.4%']")
              expect(subject).to have_css(".percent-bar-width[style*='width: 9.1%']")
              expect(subject).to have_no_css(".percent-bar-width[style*='width: 100%']")
            end

            it "shows the points-share percentage and a votes/points line" do
              expect(subject).to have_text("54.5%")
              expect(subject).to have_text("2 votes, 6 points", normalize_ws: true)
              expect(subject).to have_text("1 vote, 1 point", normalize_ws: true)
            end

            it "keeps the borda and upstream live-update hooks" do
              expect(subject).to have_css("[data-option-borda-score-width='#{question.id},#{option_a.id}']")
              expect(subject).to have_css("[data-option-borda-score-text='#{question.id},#{option_a.id}']")
              expect(subject).to have_css("[data-option-votes-count-text='#{question.id},#{option_a.id}']")
            end
          end

          describe "TOTAL footer" do
            it "totals votes and points and drops the ballots hook" do
              expect(subject).to have_text("5 votes, 11 points", normalize_ws: true)
              expect(subject).to have_css("[data-question-total-votes-text='#{question.id}']")
              expect(subject).to have_css("[data-question-total-score-text='#{question.id}']")
              expect(subject).to have_no_css("[data-question-borda-ballots-text]")
            end
          end

          describe "label gate" do
            let!(:option_a) { create(:election_response_option, question:, body: { "en" => "Alpha" }, settings: label_settings("First", 1)) }
            let!(:option_c) { create(:election_response_option, question:, body: { "en" => "Gamma" }, settings: label_settings("Second", 2)) }

            context "when results are public (election finished)" do
              it "shows badges and orders labeled options by position, unlabeled last" do
                expect(subject).to have_css("strong.label", text: "First")
                expect(subject).to have_css("strong.label", text: "Second")
                # labeled by position: Alpha(1), Gamma(2); unlabeled Beta keeps default order
                text = subject.text
                expect(text.index("Alpha")).to be < text.index("Gamma")
                expect(text.index("Gamma")).to be < text.index("Beta")
              end
            end

            context "when results are not public yet (ongoing real_time)" do
              let(:election) { create(:election, :real_time, :ongoing) }

              it "hides badges and keeps the default option order" do
                expect(subject).to have_no_css("strong.label")
                text = subject.text
                expect(text.index("Alpha")).to be < text.index("Beta")
                expect(text.index("Beta")).to be < text.index("Gamma")
              end
            end
          end

          describe "grouped rendering" do
            let(:group_a) { "aaaa0001" }
            let(:group_b) { "bbbb0002" }
            let(:question) do
              create(:election_question, election:, question_type: "multiple_option",
                                         min_choices: 1, max_choices: 3,
                                         settings: {
                                           "voting_method" => "borda",
                                           "scoring_scale" => "start_from_max",
                                           "grouped" => true,
                                           "groups" => [
                                             { "id" => group_a, "title" => { "en" => "Animals" }, "position" => 0 },
                                             { "id" => group_b, "title" => { "en" => "Plants" }, "position" => 1 }
                                           ]
                                         },
                                         skip_injection: true)
            end
            let!(:option_a) { create(:election_response_option, question:, group_id: group_a, body: { "en" => "Cat" }) }
            let!(:option_b) { create(:election_response_option, question:, group_id: group_a, body: { "en" => "Dog" }) }
            let!(:option_c) { create(:election_response_option, question:, group_id: group_b, body: { "en" => "Oak" }) }

            it "renders group subheadings with their option rows" do
              expect(subject).to have_css("h3.question-group-title", text: "Animals")
              expect(subject).to have_css("h3.question-group-title", text: "Plants")
              expect(subject).to have_text("Cat")
              expect(subject).to have_text("Dog")
              expect(subject).to have_text("Oak")
            end
          end

          def label_settings(title, position)
            { "label" => { "title" => { "en" => title }, "position" => position, "color" => "green" } }
          end
        end
      end
    end
  end
end
