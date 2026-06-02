# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module VotingMethods
      module Borda
        module QuestionFormFields
          extend ActiveSupport::Concern

          included do
            attribute :scoring_scale, String, default: "start_from_max"

            validates :scoring_scale, inclusion: { in: Decidim::Elections::Question.scoring_scales }
            validate :borda_requires_multiple_option
            validate :borda_requires_max_choices

            def allows_borda?
              question_type == "multiple_option"
            end

            private

            def borda_requires_multiple_option
              return unless voting_method == "borda"
              return if allows_borda?

              errors.add(:voting_method, :invalid)
            end

            def borda_requires_max_choices
              return unless voting_method == "borda"
              return if max_choices.present? && max_choices > 1

              errors.add(:voting_method, :invalid)
            end
          end
        end
      end
    end
  end
end
