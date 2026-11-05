# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module ResponseOptionFormOverride
      extend ActiveSupport::Concern

      included do
        attribute :group_id, String
        attribute :exclusive, :boolean, default: false
      end

      def map_model(model)
        super
        self.exclusive = model.exclusive?
      end
    end
  end
end
