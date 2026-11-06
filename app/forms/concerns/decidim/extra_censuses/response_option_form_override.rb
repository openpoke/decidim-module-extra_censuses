# frozen_string_literal: true

module Decidim
  module ExtraCensuses
    module ResponseOptionFormOverride
      extend ActiveSupport::Concern

      included do
        attribute :group_id, String
      end
    end
  end
end
