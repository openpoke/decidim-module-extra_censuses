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
          let(:question) { create(:election_question, :borda, election:, max_choices: 3, body: { "en" => "Rank these" }) }
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
            it "shows the points-share percentage and a votes/points line" do
              expect(subject).to have_content("54.5%")
              expect(subject).to have_content("2 votes, 6 points", normalize_ws: true)
              expect(subject).to have_content("1 vote, 1 point", normalize_ws: true)
            end

            it "keeps the borda and upstream live-update hooks" do
              expect(subject).to have_css("[data-option-result-score-width='#{question.id},#{option_a.id}']")
              expect(subject).to have_css("[data-option-result-score-text='#{question.id},#{option_a.id}']")
              expect(subject).to have_css("[data-option-votes-count-text='#{question.id},#{option_a.id}']")
            end
          end

          describe "TOTAL footer" do
            it "totals votes and points" do
              expect(subject).to have_content("5 votes, 11 points", normalize_ws: true)
              expect(subject).to have_css("[data-question-total-votes-text='#{question.id}']")
              expect(subject).to have_css("[data-question-total-score-text='#{question.id}']")
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

          describe "winners toggle" do
            context "when the gate is open and at least one option is labeled" do
              let!(:option_a) { create(:election_response_option, question:, body: { "en" => "Alpha" }, settings: label_settings("First", 1, "Top pick")) }
              let!(:option_c) { create(:election_response_option, question:, body: { "en" => "Gamma" }, settings: label_settings("Second", 2)) }

              it "renders the toggle button carrying both labels" do
                expect(subject).to have_css("[data-controller='winners-toggle']")
                expect(subject).to have_css("button[data-winners-toggle-target='button']", text: "Show winners")
                expect(subject).to have_css("button[data-show-winners='Show winners'][data-show-results='Show results']")
              end

              it "renders the winners panel hidden, the results panel shown" do
                expect(subject).to have_css("[data-winners-toggle-target='results']")
                expect(subject).to have_css("[data-winners-toggle-target='winners'].hidden", visible: :all)
              end

              it "lists only labeled options, by position, with badge + summary + description" do
                panel = subject.find("[data-winners-toggle-target='winners']", visible: :all)
                expect(panel).to have_css("strong.label", text: "First", visible: :all)
                expect(panel).to have_css("strong.label", text: "Second", visible: :all)
                expect(panel).to have_content("Has received 2 votes, totaling 6 points (54.5%)", normalize_ws: true)
                expect(panel).to have_content("Top pick")
                expect(panel).to have_no_css("[data-option-body]", text: "Beta", visible: :all)
                text = panel.text(:all)
                expect(text.index("Alpha")).to be < text.index("Gamma")
              end
            end

            context "when no option is labeled" do
              it "renders the options view without the toggle" do
                expect(subject).to have_no_css("[data-controller='winners-toggle']")
                expect(subject).to have_no_css("button[data-winners-toggle-target='button']")
                expect(subject).to have_no_css("[data-winners-toggle-target='winners']", visible: :all)
              end
            end

            context "when options are labeled but results are not public yet (ongoing real_time)" do
              let(:election) { create(:election, :real_time, :ongoing) }
              let!(:option_a) { create(:election_response_option, question:, body: { "en" => "Alpha" }, settings: label_settings("First", 1)) }

              it "does not render the toggle" do
                expect(subject).to have_no_css("[data-controller='winners-toggle']")
                expect(subject).to have_no_css("button[data-winners-toggle-target='button']")
              end
            end
          end

          describe "ordering with an optional position" do
            context "when no labeled option has a position" do
              let!(:option_a) { create(:election_response_option, question:, body: { "en" => "Alpha" }, settings: label_settings("First", nil)) }
              let!(:option_b) { create(:election_response_option, question:, body: { "en" => "Beta" }, settings: label_settings("Second", nil)) }
              let!(:option_c) { create(:election_response_option, question:, body: { "en" => "Gamma" }, settings: label_settings("Third", nil)) }

              it "keeps the default option order" do
                text = subject.text
                expect(text.index("Alpha")).to be < text.index("Beta")
                expect(text.index("Beta")).to be < text.index("Gamma")
              end
            end

            context "when some labeled options have a position and others do not" do
              let!(:option_a) { create(:election_response_option, question:, body: { "en" => "Alpha" }, settings: label_settings("Second", 2)) }
              let!(:option_b) { create(:election_response_option, question:, body: { "en" => "Beta" }, settings: label_settings("None", nil)) }
              let!(:option_c) { create(:election_response_option, question:, body: { "en" => "Gamma" }, settings: label_settings("First", 1)) }

              it "orders positioned options first by value, position-less ones after, in the options view" do
                text = subject.text
                expect(text.index("Gamma")).to be < text.index("Alpha")
                expect(text.index("Alpha")).to be < text.index("Beta")
              end

              it "orders the winners panel the same way" do
                panel = subject.find("[data-winners-toggle-target='winners']", visible: :all)
                panel_text = panel.text(:all)
                expect(panel_text.index("Gamma")).to be < panel_text.index("Alpha")
                expect(panel_text.index("Alpha")).to be < panel_text.index("Beta")
              end
            end
          end

          describe "grouped rendering" do
            include_context "with a grouped borda question"

            let!(:option_a) { create(:election_response_option, question:, group_id: group_a_id, body: { "en" => "Cat" }) }
            let!(:option_b) { create(:election_response_option, question:, group_id: group_a_id, body: { "en" => "Dog" }) }
            let!(:option_c) { create(:election_response_option, question:, group_id: group_b_id, body: { "en" => "Oak" }) }

            it "renders group subheadings with their option rows" do
              expect(subject).to have_css("h3.question-group-title", text: "Animals")
              expect(subject).to have_css("h3.question-group-title", text: "Plants")
              expect(subject).to have_content("Cat")
              expect(subject).to have_content("Dog")
              expect(subject).to have_content("Oak")
            end
          end

          def label_settings(title, position, description = nil)
            label = { "title" => { "en" => title }, "position" => position, "color" => "green" }
            label["description"] = { "en" => description } if description
            { "label" => label }
          end
        end
      end
    end
  end
end
