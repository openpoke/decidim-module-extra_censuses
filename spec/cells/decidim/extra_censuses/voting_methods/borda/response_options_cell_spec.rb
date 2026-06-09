# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    module VotingMethods
      module Borda
        describe ResponseOptionsCell, type: :cell do
          subject { cell(cell_path, question, context:).call(state) }

          let(:cell_path) { "decidim/extra_censuses/voting_methods/borda/response_options" }
          let(:state) { :show }
          let(:context) { { votes_buffer:, voter_uid: nil } }
          let(:votes_buffer) { {} }
          let(:election) { create(:election, :ongoing) }
          let(:question) { create(:election_question, :borda, election:, max_choices: 3, scoring_scale: "start_from_max") }
          let!(:option_a) { create(:election_response_option, question:) }
          let!(:option_b) { create(:election_response_option, question:) }
          let!(:option_c) { create(:election_response_option, question:) }

          controller Decidim::PagesController

          describe "show state" do
            it "renders a row, checkbox and position select per option plus the status counter" do
              expect(subject).to have_css("[data-voter-borda-target='row']", count: 3)
              expect(subject).to have_css("input[type=checkbox][data-voter-borda-target='checkbox']", count: 3)
              expect(subject).to have_select(class: "borda-position-select", count: 3)
              expect(subject).to have_css("[data-voter-borda-target='status'] [data-voter-borda-target='counter']")
            end

            it "offers one ranked position per votable option" do
              expect(subject).to have_css(
                "select[name='response[#{question.id}][#{option_a.id}]'] option",
                count: question.max_votable_options + 1
              )
            end

            it "labels positions with the localized rank wording and no English ordinal" do
              expect(subject).to have_css(
                "select[name='response[#{question.id}][#{option_a.id}]'] option",
                text: "Rank 1 (3 points)"
              )
              expect(subject.to_s).not_to match(/\d(st|nd|rd|th)\b/)
            end

            context "when the votes buffer holds a position" do
              let(:votes_buffer) { { question.id.to_s => { option_a.id.to_s => "1" } } }

              it "checks the option and preselects its buffered position" do
                expect(subject).to have_css("#borda-checkbox-#{question.id}-#{option_a.id}[checked]")
                expect(subject).to have_css("select[name='response[#{question.id}][#{option_a.id}]'] option[value='1'][selected]")
              end
            end
          end

          describe "option state" do
            subject { cell(cell_path, question, context:).call(:option, option_a) }

            it "renders only the given option row" do
              expect(subject).to have_css("[data-voter-borda-target='row']", count: 1)
              expect(subject).to have_css("#borda-checkbox-#{question.id}-#{option_a.id}")
            end
          end

          describe "status state" do
            subject { cell(cell_path, question, context:).call(:status) }

            it "renders the live counter" do
              expect(subject).to have_css("[data-voter-borda-target='counter']")
            end
          end
        end
      end
    end
  end
end
