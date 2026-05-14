# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    # Value object for a group of response options. Built from the raw hash
    # stored under question.settings["groups"].
    class ResponseOptionGroup
      attr_reader :id, :title, :position

      def self.from_settings_hash(hash)
        new(**hash.symbolize_keys.slice(:id, :title, :position))
      end

      def initialize(id:, title:, position: 0)
        @id = id
        @title = title
        @position = position
      end

      # Called implicitly by Decidim::Attributes::Model#cast_value when
      # QuestionForm#groups coerces each entry into a ResponseOptionGroupForm.
      # See decidim-core/lib/decidim/attributes/model.rb:17.
      def to_h
        { id:, title:, position: }
      end
    end
  end
end
