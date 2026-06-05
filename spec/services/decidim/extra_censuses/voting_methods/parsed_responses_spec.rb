# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    module VotingMethods
      describe ParsedResponses do
        subject(:parsed) { described_class.new(responses:, positions:) }

        let(:responses) { [1, 2, 3] }
        let(:positions) { { 1 => 1, 2 => 2 } }

        it "exposes the responses" do
          expect(parsed.responses).to eq([1, 2, 3])
        end

        it "exposes the positions" do
          expect(parsed.positions).to eq({ 1 => 1, 2 => 2 })
        end

        context "without positions" do
          subject(:parsed) { described_class.new(responses:) }

          it "defaults positions to an empty hash" do
            expect(parsed.positions).to eq({})
          end
        end
      end
    end
  end
end
