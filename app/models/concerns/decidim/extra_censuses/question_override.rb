# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module ExtraCensuses
    # Adds the `grouped` flag and the list of response option groups, both
    # stored under the question's `settings` JSONB column.
    module QuestionOverride
      extend ActiveSupport::Concern

      def grouped?
        !!settings["grouped"]
      end

      def groups
        settings.fetch("groups", []).map { |g| Decidim::ExtraCensuses::ResponseOptionGroup.from_settings_hash(g) }.sort_by(&:position)
      end
    end
  end
end
