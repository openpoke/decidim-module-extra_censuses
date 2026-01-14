# frozen_string_literal: true

module Decidim
  module Elections
    module Admin
      # Command to configure survey import mapping for census.
      class ConfigureSurveyImport < Decidim::Commands::UpdateResource
        def attributes
          {
            census_settings: updated_census_settings
          }
        end

        private

        def updated_census_settings
          current_settings = resource.census_settings || {}
          current_settings["survey_import"] = {
            "survey_component_id" => form.survey_component_id,
            "survey_id" => form.survey_id,
            "field_mapping" => form.field_mapping
          }
          current_settings
        end
      end
    end
  end
end
