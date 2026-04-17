# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Elections
    module Admin
      describe QuestionForm do
        let!(:questionable) { create(:election) }
        let(:question_type) { "multiple_option" }
        let(:body_en) { "Body en" }
        let(:description_en) { "Description en" }
        let(:response_options) do
          {
            "0" => { "body" => { "en" => "Option A" } },
            "1" => { "body" => { "en" => "Option B" } },
            "2" => { "body" => { "en" => "Option C" } },
            "3" => { "body" => { "en" => "Option D" } }
          }
        end
        let(:min_choices) { nil }
        let(:max_choices) { nil }

        let(:attributes) do
          {
            body_en:,
            description_en:,
            question_type:,
            response_options:,
            min_choices:,
            max_choices:
          }
        end

        subject do
          described_class.from_params(
            question: attributes
          ).with_context(current_organization: questionable.organization)
        end

        describe "min_choices attribute" do
          it "is exposed on the form" do
            expect(subject).to respond_to(:min_choices)
          end

          it "casts string input to integer" do
            form = described_class.from_params(question: attributes.merge(min_choices: "2"))
                                  .with_context(current_organization: questionable.organization)
            expect(form.min_choices).to eq(2)
          end
        end

        describe "min_choices validation" do
          context "when min_choices is nil" do
            let(:min_choices) { nil }

            it { is_expected.to be_valid }
          end

          context "when min_choices is a blank string" do
            let(:min_choices) { "" }

            it { is_expected.to be_valid }
          end

          context "when min_choices equals 1" do
            let(:min_choices) { 1 }

            it { is_expected.to be_valid }
          end

          context "when min_choices equals the number of response options and max is blank" do
            let(:min_choices) { 4 }

            it { is_expected.to be_valid }
          end

          context "when min_choices is below 1" do
            let(:min_choices) { 0 }

            it { is_expected.not_to be_valid }

            it "adds an error on :min_choices" do
              subject.valid?
              expect(subject.errors[:min_choices]).not_to be_empty
            end
          end

          context "when min_choices exceeds the number of response options and max is blank" do
            let(:min_choices) { 5 }

            it { is_expected.not_to be_valid }

            it "adds an error on :min_choices" do
              subject.valid?
              expect(subject.errors[:min_choices]).not_to be_empty
            end
          end

          context "when max_choices is set and min_choices equals it" do
            let(:max_choices) { 3 }
            let(:min_choices) { 3 }

            it { is_expected.to be_valid }
          end

          context "when max_choices is set and min_choices is less than it" do
            let(:max_choices) { 3 }
            let(:min_choices) { 2 }

            it { is_expected.to be_valid }
          end

          context "when max_choices is set and min_choices exceeds it" do
            let(:max_choices) { 2 }
            let(:min_choices) { 3 }

            it { is_expected.not_to be_valid }

            it "adds an error on :min_choices" do
              subject.valid?
              expect(subject.errors[:min_choices]).not_to be_empty
            end
          end
        end

        describe "#number_of_options" do
          context "when there are no deleted options" do
            it "returns the count of all response options" do
              expect(subject.number_of_options).to eq(4)
            end
          end

          context "when some options are marked as deleted" do
            let(:response_options) do
              {
                "0" => { "body" => { "en" => "Option A" } },
                "1" => { "body" => { "en" => "Option B" }, "deleted" => "true" },
                "2" => { "body" => { "en" => "Option C" } },
                "3" => { "body" => { "en" => "Option D" }, "deleted" => "true" }
              }
            end

            it "excludes deleted options from the count" do
              expect(subject.number_of_options).to eq(2)
            end
          end

          context "when all options are marked as deleted" do
            let(:response_options) do
              {
                "0" => { "body" => { "en" => "Option A" }, "deleted" => "true" },
                "1" => { "body" => { "en" => "Option B" }, "deleted" => "true" }
              }
            end

            it "returns zero" do
              expect(subject.number_of_options).to eq(0)
            end
          end
        end

        describe "original behavior is preserved" do
          context "when everything is OK" do
            it { is_expected.to be_valid }
          end

          context "when the question_type is unknown" do
            let(:question_type) { "foo" }

            it { is_expected.not_to be_valid }
          end

          context "when there are no response options" do
            let(:response_options) { {} }

            it { is_expected.not_to be_valid }
          end

          context "when the body is missing the locale translation" do
            let(:body_en) { "" }

            it { is_expected.not_to be_valid }
          end
        end
      end
    end
  end
end
