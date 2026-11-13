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
        if exclusive_chosen?(response_ids)
          return if chosen_option_ids(response_ids).one?

          return reject_vote(response_ids, I18n.t("exclusive_option_combined", scope: "decidim.elections.votes.question"))
        end
        return reject_vote(response_ids, choices_range_alert_message) if out_of_choices_range?(response_ids)

        reject_vote(response_ids, I18n.t("must_select_one_per_group", scope: "decidim.elections.votes.question")) if missing_group_coverage?(response_ids)
      end

      def reject_vote(response_ids, message)
        votes_buffer[question.id.to_s] = response_ids
        flash.now[:alert] = message
        render :show
      end

      def exclusive_chosen?(response_ids)
        return false unless question.exclusive_option?

        exclusive = question.exclusive_response_option
        exclusive.present? && chosen_option_ids(response_ids).map(&:to_s).include?(exclusive.id.to_s)
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
        question.response_options.where(id: chosen_option_ids(response_ids)).count
      end

      def chosen_option_ids(response_ids)
        payload = response_ids.try(:to_unsafe_h) || response_ids
        return Array(payload) unless payload.is_a?(Hash)

        payload.reject { |_option_id, position| position.to_s.strip.empty? }.keys
      end

      def choices_range_alert_message
        min = question.min_choices.presence
        max = question.max_choices.presence
        scope = "decidim.elections.votes.question"

        return I18n.t("choices_out_of_range", min:, max:, scope:) if min && max
        return I18n.t("min_choices_not_met", min:, scope:) if min

        I18n.t("max_choices_exceeded", max:, scope:)
      end

      def missing_group_coverage?(response_ids)
        return false unless question.grouped? && question.force_one_answer_per_group?
        return false if question.groups.empty?

        selected_group_ids = question.response_options
                                     .where(id: chosen_option_ids(response_ids))
                                     .pluck(:group_id)
                                     .to_set

        question.groups.any? { |group| selected_group_ids.exclude?(group.id) }
      end
    end
  end
end
