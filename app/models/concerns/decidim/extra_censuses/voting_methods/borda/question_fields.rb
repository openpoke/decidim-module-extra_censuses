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

          def borda_points(position, ranked_options_count)
            return 0 if position.to_i < 1

            base = scoring_scale == "start_from_min" ? ranked_options_count.to_i : max_votable_options
            base - position.to_i + 1
          end

          private

          def valid_scoring_scale
            return if self.class.scoring_scales.include?(scoring_scale)

            errors.add(:scoring_scale, :invalid)
          end
        end
      end
    end
  end
end
