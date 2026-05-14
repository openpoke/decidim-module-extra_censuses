# frozen_string_literal: true

module Decidim
  module ExtraCensuses
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
            position: index,
            settings: serialized_settings(question, question_form)
          )

          Decidim.traceability.perform_action!(
            "update",
            question,
            @form.current_user,
            election: @election
          ) do
            question.save!
            update_response_options(question, question_form)
          end
        end

        def update_response_options(question, question_form)
          question_form.response_options.each do |option_form|
            next delete_response_option(question, option_form) if option_form.deleted?

            save_response_option(question, option_form, question_form.grouped?)
          end
        end

        def save_response_option(question, option_form, grouped)
          option = question.response_options.find_by(id: option_form.id) || question.response_options.build
          option.body = option_form.body
          option.group_id = grouped ? option_form.group_id.presence : nil
          option.save!
        end

        def serialized_settings(question, question_form)
          base = question.settings.merge("grouped" => question_form.grouped?)
          return base.merge("groups" => []) unless question_form.grouped?

          base.merge(
            "groups" => question_form.groups_to_persist.map do |group_form|
              {
                "id" => group_form.id,
                "title" => group_form.title,
                "position" => group_form.position.to_i
              }
            end
          )
        end
      end
    end
  end
end
