# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module ApplicationHelperOverride
      extend ActiveSupport::Concern

      included do
        def question_title(question, tag = :h3, **options)
          title = decidim_sanitize_translated(question.body)
          hint = choices_hint(question)
          title = safe_join([title, " (", hint, ")"]) if hint.present?
          content_tag(tag, title, **options)
        end

        private

        def choices_hint(question)
          return unless question.question_type == "multiple_option"

          min = question.min_choices.presence
          max = question.max_choices.presence
          scope = "decidim.elections.votes.question"

          return t("choices_range", min:, max:, scope:) if min && max
          return t("min_choices", count: min, scope:) if min

          t("max_choices", count: max, scope:) if max
        end
      end
    end
  end
end
