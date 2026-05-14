# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module Elections
      module Admin
        class ResponseOptionGroupForm < Decidim::Form
          mimic :response_option_group

          include Decidim::TranslatableAttributes

          attribute :id, String
          attribute :position, Integer, default: 0
          attribute :deleted, Boolean, default: false

          translatable_attribute :title, String

          validates :id, presence: true, unless: :deleted

          def to_param
            return id if id.present?

            "questionnaire-question-response-option-group-id"
          end
        end
      end
    end
  end
end
