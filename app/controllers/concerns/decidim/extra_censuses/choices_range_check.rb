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
        if out_of_choices_range?(response_ids)
          flash.now[:alert] = choices_range_alert_message
          return render :show
        end

        if missing_group_coverage?(response_ids)
          flash.now[:alert] = I18n.t("must_select_one_per_group", scope: "decidim.elections.votes.question")
          render :show
        end
      end

      def out_of_choices_range?(response_ids)
        min = question.min_choices.presence
        max = question.max_choices.presence

        return false if min.nil? && max.nil?

        count = question.response_options.where(id: response_ids).count
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

      def missing_group_coverage?(response_ids)
        return false unless question.grouped? && question.force_one_answer_per_group?
        return false if question.groups.empty?

        selected_group_ids = question.response_options
                                     .where(id: response_ids)
                                     .pluck(:group_id)
                                     .to_set

        question.groups.any? { |group| selected_group_ids.exclude?(group.id) }
      end
    end
  end
end
