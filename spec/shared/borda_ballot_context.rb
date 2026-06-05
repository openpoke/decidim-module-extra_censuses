# frozen_string_literal: true

RSpec.shared_context "with a borda question" do
  let(:election) { create(:election, :ongoing) }
  let(:question) { create(:election_question, :borda, election:, max_choices: 4, scoring_scale:) }
  let(:scoring_scale) { "start_from_max" }
  let!(:option_a) { create(:election_response_option, question:) }
  let!(:option_b) { create(:election_response_option, question:) }
  let!(:option_c) { create(:election_response_option, question:) }
  let!(:option_d) { create(:election_response_option, question:) }

  def cast(voter_uid, ranks)
    ranks.each do |option, position|
      create(:election_vote, question:, response_option: option, voter_uid:, position:)
    end
  end
end

RSpec.shared_context "with a ranked borda ballot" do
  include_context "with a borda question"

  before do
    # max_choices = 4, start_from_max => pts = 4 - position + 1
    # voter 1: A=1 (4), B=2 (3), C=3 (2); voter 2: B=1 (4), A=2 (3) => A=7, B=7, C=2, D=0
    cast("voter-1", { option_a => 1, option_b => 2, option_c => 3 })
    cast("voter-2", { option_b => 1, option_a => 2 })
  end
end
