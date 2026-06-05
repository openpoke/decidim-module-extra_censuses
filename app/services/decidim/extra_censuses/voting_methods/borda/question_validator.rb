# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module VotingMethods
      module Borda
        class QuestionValidator
          def validate(question)
            borda_requires_max_choices(question)
            borda_requires_multiple_option(question)
          end

          private

          def borda_requires_max_choices(question)
            return unless question.voting_method == "borda"
            return if question.max_choices.present? && question.max_choices > 1

            question.errors.add(:voting_method, :invalid)
          end

          def borda_requires_multiple_option(question)
            return unless question.voting_method == "borda"
            return if question.allows_borda?

            question.errors.add(:voting_method, :invalid)
          end
        end
      end
    end
  end
end
