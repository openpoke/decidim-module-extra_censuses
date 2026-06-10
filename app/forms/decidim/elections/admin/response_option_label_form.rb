# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      # Form to set the winner label on an election response option.
      class ResponseOptionLabelForm < Decidim::Form
        include Decidim::TranslatableAttributes

        mimic :response_option_label

        translatable_attribute :title, String
        translatable_attribute :description, String
        attribute :color, String
        attribute :position, Integer

        validates :title, translatable_presence: true
        validates :description, translatable_presence: true
        validates :color, inclusion: { in: Decidim::ExtraCensuses.label_colors.keys.map(&:to_s) }

        def self.from_model(response_option)
          label = response_option.label
          return new unless label

          new(
            title: label.title,
            description: label.description,
            position: label.position,
            color: label.color
          )
        end
      end
    end
  end
end
