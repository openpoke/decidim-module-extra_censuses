# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Elections
    describe ApplicationHelper do
      let(:organization) { create(:organization) }

      before do
        allow(helper).to receive(:current_organization).and_return(organization)
      end

      describe "#question_title" do
        subject(:rendered) { helper.question_title(question) }

        context "when the question is single_option" do
          let(:question) do
            build(:election_question,
                  body: { "en" => "Pick one" },
                  question_type: "single_option",
                  max_choices: nil,
                  min_choices: nil)
          end

          it "renders just the body without any hint" do
            expect(rendered).to eq("<h3>Pick one</h3>")
          end
        end

        context "when the question is multiple_option without any range" do
          let(:question) do
            build(:election_question,
                  body: { "en" => "Pick any" },
                  question_type: "multiple_option",
                  max_choices: nil,
                  min_choices: nil)
          end

          it "renders just the body without any hint" do
            expect(rendered).to eq("<h3>Pick any</h3>")
          end
        end

        context "when the question has only max_choices set" do
          let(:question) do
            build(:election_question,
                  body: { "en" => "Pick up to some" },
                  question_type: "multiple_option",
                  max_choices: 3,
                  min_choices: nil)
          end

          it "renders the body with a max_choices hint" do
            expect(rendered).to include("Pick up to some")
            expect(rendered).to match(/Max choices: 3|Max 3/)
          end
        end

        context "when the question has only min_choices set" do
          let(:question) do
            build(:election_question,
                  body: { "en" => "Pick at least some" },
                  question_type: "multiple_option",
                  max_choices: nil,
                  min_choices: 2)
          end

          it "renders the body with a min_choices hint" do
            expect(rendered).to include("Pick at least some")
            expect(rendered).to include("Select at least 2")
          end
        end

        context "when the question has both min_choices and max_choices set" do
          let(:question) do
            build(:election_question,
                  body: { "en" => "Pick within a range" },
                  question_type: "multiple_option",
                  max_choices: 4,
                  min_choices: 2)
          end

          it "renders the body with a range hint" do
            expect(rendered).to include("Pick within a range")
            expect(rendered).to include("Select between 2 and 4 options")
          end
        end

        context "when a custom tag is requested" do
          let(:question) do
            build(:election_question,
                  body: { "en" => "Custom tag" },
                  question_type: "single_option",
                  max_choices: nil,
                  min_choices: nil)
          end

          it "renders the body inside the requested tag" do
            expect(helper.question_title(question, :h2)).to eq("<h2>Custom tag</h2>")
          end
        end
      end

      describe "#choices_hint" do
        subject { helper.send(:choices_hint, question) }

        context "when the question is not multiple_option" do
          let(:question) do
            build(:election_question,
                  question_type: "single_option",
                  max_choices: 3,
                  min_choices: 2)
          end

          it { is_expected.to be_nil }
        end

        context "when neither min nor max is set" do
          let(:question) do
            build(:election_question,
                  question_type: "multiple_option",
                  max_choices: nil,
                  min_choices: nil)
          end

          it { is_expected.to be_nil }
        end

        context "when only max is set" do
          let(:question) do
            build(:election_question,
                  question_type: "multiple_option",
                  max_choices: 3,
                  min_choices: nil)
          end

          it "returns the max_choices hint" do
            expect(subject).to include("3")
          end
        end

        context "when only min is set" do
          let(:question) do
            build(:election_question,
                  question_type: "multiple_option",
                  max_choices: nil,
                  min_choices: 2)
          end

          it "returns the min_choices hint" do
            expect(subject).to include("2")
          end
        end

        context "when both min and max are set" do
          let(:question) do
            build(:election_question,
                  question_type: "multiple_option",
                  max_choices: 4,
                  min_choices: 2)
          end

          it "returns the range hint" do
            expect(subject).to include("2")
            expect(subject).to include("4")
          end
        end
      end
    end
  end
end
