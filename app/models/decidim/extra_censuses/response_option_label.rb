# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    # Value object for a response option's winner label. Built from the raw
    # hash stored in response_option.label.
    class ResponseOptionLabel
      attr_reader :title, :description, :position, :color

      def initialize(attributes = {})
        attrs = (attributes || {}).symbolize_keys
        @title = attrs[:title] || {}
        @description = attrs[:description] || {}
        @position = attrs[:position].to_i
        @color = attrs[:color]
      end

      # Kept for Decidim::Attributes::Model#cast_value coercion — do not strip
      # (mirror of ResponseOptionGroup#to_h).
      def to_h
        { title:, description:, position:, color: }
      end

      def present?
        title.present? && title.values.any?(&:present?)
      end

      def blank?
        !present?
      end
    end
  end
end
