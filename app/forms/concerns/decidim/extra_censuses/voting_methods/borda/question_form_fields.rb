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
            validate :borda_voting_method_valid

            def allows_borda?
              question_type == "multiple_option"
            end

            private

            def borda_voting_method_valid
              Decidim::ExtraCensuses::VotingMethods::Borda::QuestionValidator.new.validate(self)
            end
          end

          def map_model(model)
            super
            self.scoring_scale = model.scoring_scale
          end

          def voting_method_settings
            super.merge("scoring_scale" => scoring_scale)
          end
        end
      end
    end
  end
end
