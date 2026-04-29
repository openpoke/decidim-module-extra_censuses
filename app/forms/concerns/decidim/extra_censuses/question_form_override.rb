# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module QuestionFormOverride
      extend ActiveSupport::Concern

      included do
        attribute :min_choices, Integer
        attribute :grouped, :boolean, default: false
        attribute :groups, [Decidim::ExtraCensuses::Elections::Admin::ResponseOptionGroupForm]
        attribute :force_one_answer_per_group, :boolean, default: false
        validates :force_one_answer_per_group, absence: true, unless: :grouped?

        validates :min_choices,
                  numericality: {
                    only_integer: true,
                    greater_than_or_equal_to: 1,
                    less_than_or_equal_to: ->(form) { form.max_choices.presence || form.number_of_options }
                  },
                  allow_blank: true
        validates :min_choices, absence: true, unless: :allows_min_choices?

        validate :grouped_requires_multiple_option, if: :grouped?
        validate :must_have_at_least_one_non_empty_group, if: :grouped?
        validate :non_empty_groups_have_title, if: :grouped?
        validate :groups_have_unique_ids, if: :grouped?
        validate :response_options_have_valid_group_id, if: :grouped?

        # Replaces upstream `response_options.size` so the min/max_choices
        # upper bound excludes options the admin has marked for deletion.
        def number_of_options
          response_options.reject(&:deleted?).size
        end

        def allows_min_choices?
          question_type == "multiple_option"
        end

        def groups_to_persist
          live_options = response_options.reject(&:deleted?)
          groups.reject do |group|
            group.deleted || live_options.none? { |opt| opt.group_id == group.id }
          end
        end

        def map_model(model)
          self.grouped = model.grouped?
          self.force_one_answer_per_group = model.force_one_answer_per_group?
        end

        private

        def grouped_requires_multiple_option
          return if question_type == "multiple_option"

          errors.add(:grouped, :invalid)
        end

        def must_have_at_least_one_non_empty_group
          return if groups_to_persist.any?

          errors.add(:groups, :blank)
        end

        def groups_have_unique_ids
          ids = groups_to_persist.map(&:id)
          return if ids.size == ids.uniq.size

          errors.add(:groups, :invalid)
        end

        def non_empty_groups_have_title
          groups_to_persist.each do |group|
            next if group.title.is_a?(Hash) && group.title.values.any?(&:present?)

            errors.add(:groups, :title_blank)
          end
        end

        def response_options_have_valid_group_id
          known_ids = groups_to_persist.map(&:id)
          response_options.reject(&:deleted?).each do |option|
            next if option.group_id.present? && known_ids.include?(option.group_id)

            errors.add(:response_options, :invalid)
            break
          end
        end
      end
    end
  end
end
