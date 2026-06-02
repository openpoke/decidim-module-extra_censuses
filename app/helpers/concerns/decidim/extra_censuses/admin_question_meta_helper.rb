# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module ExtraCensuses
    module AdminQuestionMetaHelper
      extend ActiveSupport::Concern

      included do
        def question_meta_chips(question)
          scope = "decidim.extra_censuses.elections.admin.dashboard.questions.meta"
          chips = []

          chips << t("scoring_scale.#{question.scoring_scale}", scope:) if question.voting_method == "borda"
          chips << question_meta_choices_chip(question, scope) if question_meta_choices?(question)

          chips
        end

        private

        def question_meta_choices?(question)
          question.question_type == "multiple_option" &&
            (question.min_choices.present? || question.max_choices.present?)
        end

        def question_meta_choices_chip(question, scope)
          min = question.min_choices.presence
          max = question.max_choices.presence

          return t("choices.range", scope:, min:, max:) if min && max
          return t("choices.up_to", scope:, max:) if max

          t("choices.at_least", scope:, min:)
        end
      end
    end
  end
end
