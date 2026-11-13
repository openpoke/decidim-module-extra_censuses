# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module ResponseOptionOverride
      extend ActiveSupport::Concern

      included do
        include Decidim::Loggable
      end

      def label
        @label ||= begin
          raw = settings["label"]
          Decidim::ExtraCensuses::ResponseOptionLabel.new(raw) if raw.present?
        end
      end

      def labeled?
        label.present?
      end

      def exclusive?
        !!settings["exclusive"]
      end

      def voters_percent
        @voters_percent ||= Decidim::ExtraCensuses::ResultsHelper.percentage(votes_count, question.voters_count)
      end
    end
  end
end
