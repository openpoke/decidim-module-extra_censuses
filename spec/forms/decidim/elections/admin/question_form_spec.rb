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

        describe "grouped attribute" do
          let(:grouped) { true }
          let(:groups) do
            {
              "0" => { "id" => "g1aaaaaa", "title_en" => "Group 1", "position" => 0 },
              "1" => { "id" => "g2bbbbbb", "title_en" => "Group 2", "position" => 1 }
            }
          end
          let(:response_options) do
            {
              "0" => { "body" => { "en" => "Option A" }, "group_id" => "g1aaaaaa" },
              "1" => { "body" => { "en" => "Option B" }, "group_id" => "g2bbbbbb" }
            }
          end

          subject do
            described_class.from_params(
              question: attributes.merge(grouped:, groups:)
            ).with_context(current_organization: questionable.organization)
          end

          it "is exposed on the form" do
            expect(subject).to respond_to(:grouped)
          end

          it "casts string '1' to true" do
            form = described_class.from_params(question: attributes.merge(grouped: "1", groups:))
                                  .with_context(current_organization: questionable.organization)
            expect(form.grouped).to be true
          end

          it "defaults to false when missing" do
            form = described_class.from_params(question: attributes)
                                  .with_context(current_organization: questionable.organization)
            expect(form.grouped).to be false
          end
        end

        describe "grouped validations" do
          let(:groups) do
            {
              "0" => { "id" => "g1aaaaaa", "title_en" => "Group 1", "position" => 0 }
            }
          end
          let(:response_options) do
            {
              "0" => { "body" => { "en" => "Option A" }, "group_id" => "g1aaaaaa" }
            }
          end

          subject do
            described_class.from_params(
              question: attributes.merge(grouped: true, groups:)
            ).with_context(current_organization: questionable.organization)
          end

          context "with one group containing one option" do
            it { is_expected.to be_valid }
          end

          describe "grouped_requires_multiple_option" do
            context "when grouped is true and question_type is single_option" do
              let(:question_type) { "single_option" }

              it { is_expected.not_to be_valid }

              it "adds an error on :grouped" do
                subject.valid?
                expect(subject.errors[:grouped]).not_to be_empty
              end
            end

            context "when grouped is false and question_type is single_option" do
              let(:question_type) { "single_option" }

              subject do
                described_class.from_params(
                  question: attributes.merge(grouped: false)
                ).with_context(current_organization: questionable.organization)
              end

              it { is_expected.to be_valid }
            end
          end

          describe "must_have_at_least_one_non_empty_group" do
            context "when groups are empty" do
              let(:groups) { {} }
              let(:response_options) do
                { "0" => { "body" => { "en" => "Option A" } } }
              end

              it { is_expected.not_to be_valid }

              it "adds an error on :groups" do
                subject.valid?
                expect(subject.errors[:groups]).not_to be_empty
              end
            end

            context "when a group exists but has no live options" do
              let(:response_options) do
                { "0" => { "body" => { "en" => "A" }, "group_id" => "g1aaaaaa", "deleted" => "true" } }
              end

              it "ignores the empty group and rejects saving" do
                expect(subject).not_to be_valid
                expect(subject.errors[:groups]).not_to be_empty
              end
            end
          end

          describe "non_empty_groups_have_title" do
            context "when a group with options has a blank title" do
              let(:groups) do
                { "0" => { "id" => "g1aaaaaa", "title_en" => "", "position" => 0 } }
              end

              it { is_expected.not_to be_valid }

              it "adds a :title_blank error on :groups" do
                subject.valid?
                expect(subject.errors.of_kind?(:groups, :title_blank)).to be true
              end
            end
          end

          describe "groups_have_unique_ids" do
            context "when two non-empty groups share the same id" do
              let(:groups) do
                {
                  "0" => { "id" => "g1aaaaaa", "title_en" => "First", "position" => 0 },
                  "1" => { "id" => "g1aaaaaa", "title_en" => "Second", "position" => 1 }
                }
              end
              let(:response_options) do
                {
                  "0" => { "body" => { "en" => "A" }, "group_id" => "g1aaaaaa" },
                  "1" => { "body" => { "en" => "B" }, "group_id" => "g1aaaaaa" }
                }
              end

              it { is_expected.not_to be_valid }

              it "adds an error on :groups" do
                subject.valid?
                expect(subject.errors[:groups]).not_to be_empty
              end
            end
          end

          describe "response_options_have_valid_group_id" do
            context "when an option references a group that doesn't exist" do
              let(:response_options) do
                {
                  "0" => { "body" => { "en" => "A" }, "group_id" => "g1aaaaaa" },
                  "1" => { "body" => { "en" => "B" }, "group_id" => "gxxxxxxx" }
                }
              end

              it { is_expected.not_to be_valid }

              it "adds an error on :response_options" do
                subject.valid?
                expect(subject.errors[:response_options]).not_to be_empty
              end
            end

            context "when an option has a blank group_id" do
              let(:response_options) do
                {
                  "0" => { "body" => { "en" => "A" }, "group_id" => "g1aaaaaa" },
                  "1" => { "body" => { "en" => "B" }, "group_id" => "" }
                }
              end

              it { is_expected.not_to be_valid }
            end
          end
        end

        describe "#groups_to_persist" do
          let(:groups) do
            {
              "0" => { "id" => "g1aaaaaa", "title_en" => "First", "position" => 0 },
              "1" => { "id" => "g2bbbbbb", "title_en" => "Second", "position" => 1 },
              "2" => { "id" => "g3cccccc", "title_en" => "Third", "position" => 2, "deleted" => "true" }
            }
          end
          let(:response_options) do
            {
              "0" => { "body" => { "en" => "A" }, "group_id" => "g1aaaaaa" },
              "1" => { "body" => { "en" => "B" }, "group_id" => "g1aaaaaa" }
            }
          end

          subject do
            described_class.from_params(
              question: attributes.merge(grouped: true, groups:)
            ).with_context(current_organization: questionable.organization)
          end

          it "drops groups marked as deleted" do
            ids = subject.groups_to_persist.map(&:id)
            expect(ids).not_to include("g3cccccc")
          end

          it "drops groups that have no live options" do
            ids = subject.groups_to_persist.map(&:id)
            expect(ids).not_to include("g2bbbbbb")
          end

          it "keeps groups that have at least one live option" do
            ids = subject.groups_to_persist.map(&:id)
            expect(ids).to include("g1aaaaaa")
          end
        end
      end
    end
  end
end
