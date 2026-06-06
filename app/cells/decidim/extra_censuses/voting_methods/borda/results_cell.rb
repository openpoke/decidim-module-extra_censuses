# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module VotingMethods
      module Borda
        # Public-facing ranked (BORDA) results for a question: a per-option bar
        # sized by each option's share of the question's total points, a
        # "votes, points" line, label badges once the results gate is open, and a
        # points/votes total. Mirrors the upstream `_vote_results_option` markup so
        # the live poller keeps updating the same data-* hooks.
        class ResultsCell < Decidim::ViewModel
          include Decidim::ExtraCensuses::ResultsHelper
          include Decidim::ExtraCensuses::GroupedResponseOptionsHelper

          def show
            render
          end

          private

          def election
            model.election
          end

          # Labels (and the ordering they drive) only surface once results are
          # public: per-question elections gate on the question, otherwise on the
          # whole election being finished.
          def label_shown?
            election.per_question? ? model.published_results? : election.finished?
          end

          def response_groups
            return [[nil, model.response_options.to_a]] unless model.grouped?

            grouped_response_options(model)
          end

          # Labeled options first by label position, unlabeled after in their
          # default order; the index tiebreaker keeps the unstable sort_by
          # deterministic for equal positions.
          def ordered_options(options)
            return options unless label_shown?

            options.each_with_index.sort_by do |option, index|
              [option.labeled? ? 0 : 1, option.label&.position.to_i, index]
            end.map(&:first)
          end
        end
      end
    end
  end
end
