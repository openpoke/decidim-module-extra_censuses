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

      # Inline badge style, mirrors Decidim::Proposals::ProposalState#css_style.
      def css_style
        colors = Decidim::ExtraCensuses.label_colors[color&.to_sym]
        return "" unless colors

        "background-color: #{colors[:background]}; color: #{colors[:foreground]}; border-color: #{colors[:foreground]};"
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
