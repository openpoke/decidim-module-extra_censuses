# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module ResponseOptionOverride
      extend ActiveSupport::Concern

      def label
        raw = settings["label"]
        return if raw.blank?

        Decidim::ExtraCensuses::ResponseOptionLabel.new(raw)
      end

      def labeled?
        label.present?
      end
    end
  end
end
