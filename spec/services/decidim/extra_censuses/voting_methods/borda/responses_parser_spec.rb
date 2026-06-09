# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ExtraCensuses
    module VotingMethods
      module Borda
        describe ResponsesParser do
          subject(:parser) { described_class.new(question) }

          let(:election) { create(:election, :ongoing) }
          let(:question) { create(:election_question, :borda, :voting_enabled, election:, max_choices: 4, min_choices: 2) }
          let!(:opt_a) { create(:election_response_option, question:) }
          let!(:opt_b) { create(:election_response_option, question:) }
          let!(:opt_c) { create(:election_response_option, question:) }

          describe "#parse" do
            context "with a valid contiguous vote" do
              let(:payload) { { opt_a.id.to_s => 1, opt_b.id.to_s => 2, opt_c.id.to_s => 3 } }

              it "returns a ParsedResponses with responses and positions" do
                parsed = parser.parse(payload)

                expect(parsed).to be_a(Decidim::ExtraCensuses::VotingMethods::ParsedResponses)
                expect(parsed.responses).to contain_exactly(opt_a, opt_b, opt_c)
                expect(parsed.positions).to eq(opt_a.id => 1, opt_b.id => 2, opt_c.id => 3)
              end
            end

            context "with a non-numeric payload" do
              let(:payload) { { opt_a.id.to_s => "first", opt_b.id.to_s => "second" } }

              it "returns nil" do
                expect(parser.parse(payload)).to be_nil
              end
            end

            context "when the payload is not a hash" do
              let(:payload) { [opt_a.id.to_s, opt_b.id.to_s] }

              it "returns nil" do
                expect(parser.parse(payload)).to be_nil
              end
            end

            context "when response options do not match the positions" do
              let(:payload) { { opt_a.id.to_s => 1, "999999" => 2 } }

              it "returns nil on size mismatch" do
                expect(parser.parse(payload)).to be_nil
              end
            end

            context "when ranks are blank" do
              let(:payload) { { opt_a.id.to_s => 1, opt_b.id.to_s => "" } }

              it "skips blank ranks" do
                parsed = parser.parse(payload)

                expect(parsed.positions).to eq(opt_a.id => 1)
                expect(parsed.responses).to contain_exactly(opt_a)
              end
            end
          end

          describe "#validate!" do
            def build_parsed(positions)
              responses = question.response_options.where(id: positions.keys).to_a
              Decidim::ExtraCensuses::VotingMethods::ParsedResponses.new(responses:, positions:)
            end

            context "with a valid contiguous vote" do
              it "does not raise" do
                parsed = build_parsed(opt_a.id => 1, opt_b.id => 2)
                expect { parser.validate!(parsed) }.not_to raise_error
              end
            end

            context "when the vote is empty" do
              it "raises" do
                parsed = build_parsed({})
                expect { parser.validate!(parsed) }.to raise_error(StandardError)
              end
            end

            context "when the vote is below min_choices" do
              it "raises" do
                parsed = build_parsed(opt_a.id => 1)
                expect { parser.validate!(parsed) }.to raise_error(StandardError)
              end
            end

            context "when the vote is above max_choices" do
              let(:question) { create(:election_question, :borda, :voting_enabled, election:, max_choices: 2, min_choices: 1) }

              it "raises" do
                parsed = build_parsed(opt_a.id => 1, opt_b.id => 2, opt_c.id => 3)
                expect { parser.validate!(parsed) }.to raise_error(StandardError)
              end
            end

            context "when positions are not contiguous" do
              it "raises" do
                parsed = build_parsed(opt_a.id => 1, opt_b.id => 3)
                expect { parser.validate!(parsed) }.to raise_error(StandardError)
              end
            end
          end
        end
      end
    end
  end
end
