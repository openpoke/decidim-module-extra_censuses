# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    # Enforces min_choices/max_choices range on the #update action of both
    # voting controllers. Included directly into VotesController and
    # PerQuestionVotesController — no wrapper override needed.
    module ChoicesRangeCheck
      extend ActiveSupport::Concern

      included do
        before_action :check_choices_range!, only: :update # rubocop:disable Rails/LexicallyScopedActionFilter
      end

      private

      def check_choices_range!
        response_ids = params.dig(:response, question.id.to_s) || []
        return unless out_of_choices_range?(response_ids)

        votes_buffer[question.id.to_s] = response_ids
        flash.now[:alert] = choices_range_alert_message
        render :show
      end

      def out_of_choices_range?(response_ids)
        min = question.min_choices.presence
        max = question.max_choices.presence

        return false if min.nil? && max.nil?

        count = chosen_options_count(response_ids)
        return true if min && count < min
        return true if max && count > max

        false
      end

      # Borda votes arrive as { option_id => position }; standard votes as an
      # array of option ids. Both reduce to a set of chosen option ids; blank
      # (unranked) positions are ignored.
      def chosen_options_count(response_ids)
        payload = response_ids.try(:to_unsafe_h) || response_ids
        ids = if payload.is_a?(Hash)
                payload.reject { |_option_id, position| position.to_s.strip.empty? }.keys
              else
                Array(payload)
              end
        question.response_options.where(id: ids).count
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
