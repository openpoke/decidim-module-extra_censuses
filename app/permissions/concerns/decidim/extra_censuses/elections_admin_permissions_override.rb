# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module ElectionsAdminPermissionsOverride
      def permissions
        toggle_allow(label_editable?) if updating_response_option_label?
        super
      end

      private

      def updating_response_option_label?
        permission_action.subject == :response_option_label && permission_action.action == :update
      end

      def label_editable?
        question = context.fetch(:resource, nil)
        return false unless question

        election = question.election
        return !question.published_results? if election.per_question?
        return !election.finished? if election.real_time?

        !election.published_results?
      end
    end
  end
end
