# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Elections
    describe CastVotes do
      subject { described_class.new(election, data, voter_uid) }

      let(:election) { create(:election, :ongoing) }
      let(:voter_uid) { "voter_#{SecureRandom.hex(4)}" }

      let!(:borda_question) do
        create(:election_question, :borda, :voting_enabled, election:, max_choices: 4, min_choices: 2)
      end
      let!(:b_opt_a) { create(:election_response_option, question: borda_question) }
      let!(:b_opt_b) { create(:election_response_option, question: borda_question) }
      let!(:b_opt_c) { create(:election_response_option, question: borda_question) }

      let!(:standard_question) do
        create(:election_question, :voting_enabled, election:, question_type: "multiple_option", max_choices: 2)
      end
      let!(:s_opt_a) { create(:election_response_option, question: standard_question) }
      let!(:s_opt_b) { create(:election_response_option, question: standard_question) }

      context "when the borda payload is valid" do
        let(:data) do
          {
            borda_question.id.to_s => {
              b_opt_a.id.to_s => 1,
              b_opt_b.id.to_s => 2,
              b_opt_c.id.to_s => 3
            },
            standard_question.id.to_s => [s_opt_a.id.to_s]
          }
        end

        it "broadcasts :ok" do
          expect { subject.call }.to broadcast(:ok)
        end

        it "persists positions on borda votes" do
          subject.call
          votes = borda_question.votes.where(voter_uid:).index_by(&:response_option_id)
          expect(votes[b_opt_a.id].position).to eq(1)
          expect(votes[b_opt_b.id].position).to eq(2)
          expect(votes[b_opt_c.id].position).to eq(3)
        end

        it "persists standard votes without position" do
          subject.call
          standard_votes = standard_question.votes.where(voter_uid:)
          expect(standard_votes.size).to eq(1)
          expect(standard_votes.first.position).to be_nil
        end
      end

      context "when borda positions are not contiguous" do
        let(:data) do
          {
            borda_question.id.to_s => {
              b_opt_a.id.to_s => 1,
              b_opt_b.id.to_s => 3
            },
            standard_question.id.to_s => [s_opt_a.id.to_s]
          }
        end

        it "broadcasts :invalid and persists nothing" do
          expect { subject.call }.to broadcast(:invalid)
          expect(borda_question.votes.where(voter_uid:)).to be_empty
          expect(standard_question.votes.where(voter_uid:)).to be_empty
        end
      end

      context "when the borda vote is below min_choices" do
        let(:data) do
          {
            borda_question.id.to_s => { b_opt_a.id.to_s => 1 },
            standard_question.id.to_s => [s_opt_a.id.to_s]
          }
        end

        it "broadcasts :invalid" do
          expect { subject.call }.to broadcast(:invalid)
        end
      end

      context "when the borda vote exceeds max_choices" do
        let(:borda_question) do
          create(:election_question, :borda, :voting_enabled, election:, max_choices: 2, min_choices: 1)
        end

        let(:data) do
          {
            borda_question.id.to_s => {
              b_opt_a.id.to_s => 1,
              b_opt_b.id.to_s => 2,
              b_opt_c.id.to_s => 3
            },
            standard_question.id.to_s => [s_opt_a.id.to_s]
          }
        end

        it "broadcasts :invalid" do
          expect { subject.call }.to broadcast(:invalid)
        end
      end

      context "when a borda-shape payload is sent to a standard question" do
        let(:data) do
          {
            borda_question.id.to_s => {
              b_opt_a.id.to_s => 1,
              b_opt_b.id.to_s => 2
            },
            standard_question.id.to_s => {
              s_opt_a.id.to_s => 1
            }
          }
        end

        it "broadcasts :invalid because the standard question payload is not an array" do
          expect { subject.call }.to broadcast(:invalid)
        end
      end

      context "when a standard-shape payload is sent to a borda question" do
        let(:data) do
          {
            borda_question.id.to_s => [b_opt_a.id.to_s, b_opt_b.id.to_s],
            standard_question.id.to_s => [s_opt_a.id.to_s]
          }
        end

        it "broadcasts :invalid because the borda question payload is not a hash" do
          expect { subject.call }.to broadcast(:invalid)
        end
      end

      context "when casting a standard vote on a per-question election" do
        let(:election) { create(:election, :ongoing, :per_question) }
        let(:data) do
          { standard_question.id.to_s => [s_opt_a.id.to_s, s_opt_b.id.to_s] }
        end

        it "broadcasts :ok and stores no positions" do
          expect { subject.call }.to broadcast(:ok)
          expect(standard_question.votes.where(voter_uid:).pluck(:position)).to all(be_nil)
        end
      end
    end
  end
end
