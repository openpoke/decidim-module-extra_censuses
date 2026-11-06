# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module VotingMethods
      module Borda
        class QuestionValidator
          def validate(question)
            return unless question.voting_method == "borda"

            question.errors.add(:voting_method, :invalid) unless valid_max_choices?(question) && question.allows_borda?
            question.errors.add(:voting_method, :exclusive_option_not_allowed) if question.exclusive_option?
          end

          private

          def valid_max_choices?(question)
            question.max_choices.present? && question.max_choices > 1
          end
        end
      end
    end
  end
end
