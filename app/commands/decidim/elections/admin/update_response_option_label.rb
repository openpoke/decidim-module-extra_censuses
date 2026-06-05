# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      # Persists a winner label into a response option's generic settings,
      # preserving any other settings keys.
      class UpdateResponseOptionLabel < Decidim::Commands::UpdateResource
        def attributes
          {
            settings: resource.settings.merge(
              "label" => {
                "title" => form.title,
                "description" => form.description,
                "position" => form.position.to_i,
                "color" => form.color
              }
            )
          }
        end
      end
    end
  end
end
