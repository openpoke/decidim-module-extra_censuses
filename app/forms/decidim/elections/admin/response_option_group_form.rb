# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      # Form object for a group of response options within a grouped question.
      class ResponseOptionGroupForm < Decidim::Form
        mimic :response_option_group

        include TranslatableAttributes

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
