# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module GroupedResponseOptionsHelper
      extend ActiveSupport::Concern

      included do
        def response_option_group_forms(question)
          question.groups.map do |group|
            Decidim::ExtraCensuses::Elections::Admin::ResponseOptionGroupForm.new(
              id: group.id,
              title: group.title,
              position: group.position
            )
          end
        end

        # Ungrouped options land under a nil group.
        def grouped_response_options(question)
          options_by_group = question.response_options.group_by(&:group_id)
          pairs = question.groups.map { |group| [group, options_by_group[group.id] || []] }
          ungrouped = ungrouped_response_options(question)
          pairs << [nil, ungrouped] if ungrouped.any?
          pairs
        end

        # Options whose group_id is blank or doesn't match any known group.
        # Without this fallback they become invisible dead data in the admin UI.
        def ungrouped_response_options(question)
          return [] unless question.grouped?

          known_ids = question.groups.map(&:id)
          question.response_options.reject do |opt|
            opt.group_id.present? && known_ids.include?(opt.group_id)
          end
        end

        # Non-grouped questions yield a single `group: nil` pair, so the view
        # renders both cases through one loop.
        def confirm_response_groups(question, selected_options)
          return [[nil, selected_options]] unless question.grouped?

          chosen_ids = selected_options.map(&:id)
          grouped_response_options(question).filter_map do |group, options|
            selected = options.select { |opt| chosen_ids.include?(opt.id) }
            [group, selected] if selected.any?
          end
        end
      end
    end
  end
end
