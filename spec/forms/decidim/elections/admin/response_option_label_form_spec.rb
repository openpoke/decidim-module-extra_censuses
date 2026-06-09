# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Elections
    module Admin
      describe ResponseOptionLabelForm do
        subject { described_class.from_params(response_option_label: attributes).with_context(current_organization: organization) }

        let(:organization) { create(:organization) }
        let(:title_en) { "Winner" }
        let(:description_en) { "The winning option" }
        let(:position) { 1 }
        let(:color) { "green" }
        let(:attributes) { { title_en:, description_en:, position:, color: } }

        describe "validations" do
          context "with a full valid set" do
            it { is_expected.to be_valid }
          end

          context "when title is blank" do
            let(:title_en) { "" }

            it { is_expected.not_to be_valid }
          end

          context "when description is blank" do
            let(:description_en) { "" }

            it { is_expected.not_to be_valid }
          end

          context "when color is not in the palette" do
            let(:color) { "turquoise" }

            it { is_expected.not_to be_valid }

            it "adds an error on :color" do
              subject.valid?
              expect(subject.errors[:color]).not_to be_empty
            end
          end

          context "when color is blank" do
            let(:color) { "" }

            it { is_expected.not_to be_valid }
          end

          context "when position is blank" do
            let(:position) { "" }

            it { is_expected.to be_valid }
          end
        end

        describe "attribute coercion" do
          it "coerces position to integer from a string" do
            form = described_class.from_params(response_option_label: attributes.merge(position: "3"))
            expect(form.position).to eq(3)
          end

          it "leaves position nil when blank" do
            form = described_class.from_params(response_option_label: attributes.merge(position: ""))
            expect(form.position).to be_nil
          end

          it "exposes the translatable title and description hashes" do
            expect(subject.title).to include("en" => "Winner")
            expect(subject.description).to include("en" => "The winning option")
          end
        end

        describe ".from_model" do
          context "when the response option has a label" do
            let(:response_option) { build(:election_response_option, :with_label) }

            it "prefills from the stored label" do
              form = described_class.from_model(response_option)
              expect(form.title).to include("en" => "Winner")
              expect(form.description).to include("en" => "The winning option")
              expect(form.position).to eq(1)
              expect(form.color).to eq("green")
            end
          end

          context "when the response option has no label" do
            let(:response_option) { build(:election_response_option) }

            it "returns a blank form" do
              form = described_class.from_model(response_option)
              expect(form.title).to be_blank
              expect(form.color).to be_nil
            end
          end
        end
      end
    end
  end
end
