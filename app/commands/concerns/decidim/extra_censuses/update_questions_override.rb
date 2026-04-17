# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    # Override for Decidim::Elections::Admin::UpdateQuestions.
    module UpdateQuestionsOverride
      extend ActiveSupport::Concern

      included do
        private

        def update_question(question_form, index)
          question = find_or_build_question(question_form)

          question.assign_attributes(
            body: question_form.body,
            description: question_form.description,
            question_type: question_form.question_type,
            max_choices: question_form.max_choices,
            min_choices: question_form.min_choices,
            position: index
          )

          Decidim.traceability.perform_action!(
            "update",
            question,
            @form.current_user,
            election: @election
          ) do
            question.save!
            update_response_options(question, question_form.response_options)
          end
        end
      end
    end
  end
end
