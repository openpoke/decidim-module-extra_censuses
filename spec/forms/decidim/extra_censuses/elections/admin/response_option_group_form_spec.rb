# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    module Elections
      module Admin
        describe ResponseOptionGroupForm do
          let(:id) { "abc12345" }
          let(:title_en) { "My group" }
          let(:position) { 0 }
          let(:deleted) { false }

          let(:attributes) do
            {
              id:,
              title_en:,
              position:,
              deleted:
            }
          end

          subject { described_class.from_params(response_option_group: attributes) }

          describe "validations" do
            context "with id present and not deleted" do
              it { is_expected.to be_valid }
            end

            context "with id missing and not deleted" do
              let(:id) { nil }

              it { is_expected.not_to be_valid }

              it "adds an error on :id" do
                subject.valid?
                expect(subject.errors[:id]).not_to be_empty
              end
            end

            context "with id missing but marked as deleted" do
              let(:id) { nil }
              let(:deleted) { true }

              it "does not require id" do
                expect(subject).to be_valid
              end
            end
          end

          describe "attribute coercion" do
            it "keeps id as a string" do
              expect(subject.id).to eq("abc12345")
            end

            it "preserves string ids generated client-side" do
              form = described_class.from_params(response_option_group: attributes.merge(id: "aaaa0001"))
              expect(form.id).to eq("aaaa0001")
            end

            it "coerces position to integer from a string" do
              form = described_class.from_params(response_option_group: attributes.merge(position: "3"))
              expect(form.position).to eq(3)
            end

            it "defaults position to 0 when missing" do
              form = described_class.from_params(response_option_group: attributes.except(:position))
              expect(form.position).to eq(0)
            end

            it "coerces deleted to a boolean" do
              form = described_class.from_params(response_option_group: attributes.merge(deleted: "true"))
              expect(form.deleted).to be true
            end
          end

          describe "#to_param" do
            context "when id is present" do
              it "returns the id" do
                expect(subject.to_param).to eq("abc12345")
              end
            end

            context "when id is blank" do
              let(:id) { nil }

              it "returns the placeholder for fields_for templates" do
                expect(subject.to_param).to eq("questionnaire-question-response-option-group-id")
              end
            end
          end
        end
      end
    end
  end
end
