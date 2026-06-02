# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module ExtraCensuses
    module VotingMethods
      module Borda
        module QuestionFields
          extend ActiveSupport::Concern

          included do
            validate :valid_scoring_scale
            validate :borda_requires_max_choices
            validate :borda_requires_multiple_option
          end

          class_methods do
            def scoring_scales
              %w(start_from_max start_from_min).freeze
            end
          end

          def scoring_scale
            settings.fetch("scoring_scale", "start_from_max")
          end

          def allows_borda?
            question_type == "multiple_option"
          end

          def borda_points(position, ballot_size)
            return 0 if position.to_i < 1

            base = scoring_scale == "start_from_min" ? ballot_size.to_i : max_votable_options
            base - position.to_i + 1
          end

          private

          def valid_scoring_scale
            return if self.class.scoring_scales.include?(scoring_scale)

            errors.add(:scoring_scale, :invalid)
          end

          def borda_requires_max_choices
            return unless voting_method == "borda"
            return if max_choices.present? && max_choices > 1

            errors.add(:voting_method, :invalid)
          end

          def borda_requires_multiple_option
            return unless voting_method == "borda"
            return if allows_borda?

            errors.add(:voting_method, :invalid)
          end
        end
      end
    end
  end
end
