# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    module VotingMethods
      module Borda
        describe ConfigChipsPresenter do
          subject(:chips) { described_class.new.chips(question, scope) }

          let(:scope) { "decidim.extra_censuses.elections.admin.dashboard.questions.meta" }
          let(:question) { double(scoring_scale:) }

          context "with start_from_max scoring" do
            let(:scoring_scale) { "start_from_max" }

            it "returns the standard Borda count chip" do
              expect(chips).to eq(["Standard Borda count"])
            end
          end

          context "with start_from_min scoring" do
            let(:scoring_scale) { "start_from_min" }

            it "returns the modified Borda count chip" do
              expect(chips).to eq(["Modified Borda count"])
            end
          end
        end
      end
    end
  end
end
