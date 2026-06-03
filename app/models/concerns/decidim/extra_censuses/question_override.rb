# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module ExtraCensuses
    module QuestionOverride
      extend ActiveSupport::Concern

      included do
        validate :valid_voting_method
      end

      class_methods do
        def voting_methods
          %w(approval borda).freeze
        end
      end

      def grouped?
        !!settings["grouped"]
      end

      def groups
        settings.fetch("groups", []).map { |g| Decidim::ExtraCensuses::ResponseOptionGroup.from_settings_hash(g) }.sort_by(&:position)
      end

      def voting_method
        settings.fetch("voting_method", "approval")
      end

      def voting_method_manifest
        Decidim::ExtraCensuses.voting_method_registry.find(voting_method)
      end

      private

      def valid_voting_method
        return if self.class.voting_methods.include?(voting_method)

        errors.add(:voting_method, :invalid)
      end
    end
  end
end
