# frozen_string_literal: true

require "spec_helper"

describe Decidim::ExtraCensuses::ChoicesRangeCheck do
  let(:dummy_class) do
    Class.new(ActionController::Base) do
      include Decidim::ExtraCensuses::ChoicesRangeCheck

      attr_accessor :question
    end
  end

  let(:question) { double(:question, min_choices:, max_choices:) }
  let(:instance) { dummy_class.new.tap { |o| o.question = question } }
  let(:min_choices) { nil }
  let(:max_choices) { nil }

  describe "#out_of_choices_range?" do
    subject { instance.send(:out_of_choices_range?, count) }

    context "when neither min nor max is set" do
      let(:count) { 5 }

      it { is_expected.to be(false) }

      context "when count is zero" do
        let(:count) { 0 }

        it { is_expected.to be(false) }
      end
    end

    context "when only min_choices is set" do
      let(:min_choices) { 2 }

      context "when count is below min" do
        let(:count) { 1 }

        it { is_expected.to be(true) }
      end

      context "when count equals min" do
        let(:count) { 2 }

        it { is_expected.to be(false) }
      end

      context "when count exceeds min" do
        let(:count) { 10 }

        it { is_expected.to be(false) }
      end
    end

    context "when only max_choices is set" do
      let(:max_choices) { 3 }

      context "when count is below max" do
        let(:count) { 1 }

        it { is_expected.to be(false) }
      end

      context "when count equals max" do
        let(:count) { 3 }

        it { is_expected.to be(false) }
      end

      context "when count exceeds max" do
        let(:count) { 4 }

        it { is_expected.to be(true) }
      end
    end

    context "when both min and max are set" do
      let(:min_choices) { 2 }
      let(:max_choices) { 4 }

      context "when count is below min" do
        let(:count) { 1 }

        it { is_expected.to be(true) }
      end

      context "when count equals min" do
        let(:count) { 2 }

        it { is_expected.to be(false) }
      end

      context "when count is within range" do
        let(:count) { 3 }

        it { is_expected.to be(false) }
      end

      context "when count equals max" do
        let(:count) { 4 }

        it { is_expected.to be(false) }
      end

      context "when count exceeds max" do
        let(:count) { 5 }

        it { is_expected.to be(true) }
      end
    end

    context "when min is blank string" do
      let(:min_choices) { "" }
      let(:max_choices) { 3 }
      let(:count) { 1 }

      it "treats min as not set" do
        expect(subject).to be(false)
      end
    end

    context "when max is blank string" do
      let(:min_choices) { 2 }
      let(:max_choices) { "" }
      let(:count) { 10 }

      it "treats max as not set" do
        expect(subject).to be(false)
      end
    end
  end

  describe "#choices_range_alert_message" do
    subject { instance.send(:choices_range_alert_message) }

    context "when both min and max are set" do
      let(:min_choices) { 2 }
      let(:max_choices) { 4 }

      it "returns the choices_out_of_range message with both values" do
        expect(subject).to include("between 2 and 4")
      end
    end

    context "when only min_choices is set" do
      let(:min_choices) { 3 }

      it "returns the min_choices_not_met message with the min value" do
        expect(subject).to include("at least 3")
      end
    end

    context "when only max_choices is set" do
      let(:max_choices) { 5 }

      it "returns the max_choices_exceeded message with the max value" do
        expect(subject).to include("more than 5")
      end
    end
  end
end
