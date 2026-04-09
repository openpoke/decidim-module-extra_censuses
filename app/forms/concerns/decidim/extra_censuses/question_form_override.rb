# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    # Override for Decidim::Elections::Admin::QuestionForm.
    module QuestionFormOverride
      extend ActiveSupport::Concern

      included do
        attribute :min_choices, Integer

        validates :min_choices,
                  numericality: {
                    only_integer: true,
                    greater_than_or_equal_to: 1,
                    less_than_or_equal_to: ->(form) { form.max_choices.presence || form.number_of_options }
                  },
                  allow_blank: true

        def number_of_options
          response_options.reject(&:deleted?).size
        end
      end
    end
  end
end
