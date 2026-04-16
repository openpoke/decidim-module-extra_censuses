# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    # Enforces min_choices/max_choices range on the #update action of both
    # voting controllers. Included directly into VotesController and
    # PerQuestionVotesController — no wrapper override needed.
    module ChoicesRangeCheck
      extend ActiveSupport::Concern

      included do
        prepend_before_action :check_choices_range!, only: :update # rubocop:disable Rails/LexicallyScopedActionFilter
      end

      private

      def check_choices_range!
        response_ids = params.dig(:response, question.id.to_s) || []
        return unless out_of_choices_range?(response_ids)

        flash.now[:alert] = choices_range_alert_message
        render :show
      end

      def out_of_choices_range?(response_ids)
        min = question.min_choices.presence
        max = question.max_choices.presence

        return false if min.nil? && max.nil?

        count = question.responses.where(id: response_ids).count
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
