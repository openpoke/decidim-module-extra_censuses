# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    # Shared check for min_choices/max_choices range on election votes controllers.
    # Used by both VotesController (normal voting) and PerQuestionVotesController (per_question voting).
    module ChoicesRangeCheck
      extend ActiveSupport::Concern

      private

      def out_of_choices_range?(count)
        min = question.min_choices.presence
        max = question.max_choices.presence

        return false if min.nil? && max.nil?
        return true if min && count < min
        return true if max && count > max

        false
      end

      def choices_range_alert_message
        min = question.min_choices.presence
        max = question.max_choices.presence
        scope = "decidim.elections.votes.question"

        return I18n.t("choices_out_of_range", min:, max:, scope:) if min && max
        return I18n.t("min_choices_not_met", min:, scope:) if min

        I18n.t("max_choices_exceeded", max:, scope:)
      end
    end
  end
end
