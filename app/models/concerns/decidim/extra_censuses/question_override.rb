# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module ExtraCensuses
    module QuestionOverride
      extend ActiveSupport::Concern

      included do
        validate :valid_voting_method
        validate :voting_method_config_valid
      end

      class_methods do
        def voting_methods
          ["approval", *Decidim::ExtraCensuses.voting_method_registry.manifests.map { |manifest| manifest.name.to_s }]
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

      def voting_method_config_valid
        validator = voting_method_manifest&.question_validator
        return if validator.blank?

        validator.constantize.new.validate(self)
      end
    end
  end
end
