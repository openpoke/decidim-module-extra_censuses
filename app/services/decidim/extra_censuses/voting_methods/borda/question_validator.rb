# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module VotingMethods
      module Borda
        class QuestionValidator
          def validate(question)
            return unless question.voting_method == "borda"

            question.errors.add(:voting_method, :invalid) unless valid_max_choices?(question) && question.allows_borda?
            question.errors.add(:voting_method, :exclusive_options_not_allowed) if exclusive_options?(question)
          end

          private

          def exclusive_options?(question)
            question.response_options.any? { |option| option.exclusive? && !option.try(:deleted?) }
          end

          def valid_max_choices?(question)
            question.max_choices.present? && question.max_choices > 1
          end
        end
      end
    end
  end
end
