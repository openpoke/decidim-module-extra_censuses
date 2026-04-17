import CustomCsvCensusController from "src/decidim/extra_censuses/controllers/custom_csv_census_controller"
import SurveyImportController from "src/decidim/extra_censuses/controllers/survey_import_controller"
import AdminMinChoicesController from "src/decidim/extra_censuses/admin_min_choices"

const registerControllers = () => {
  if (window.Stimulus) {
    window.Stimulus.register("custom-csv-census", CustomCsvCensusController)
    window.Stimulus.register("survey-import", SurveyImportController)
    window.Stimulus.register("admin-min-choices", AdminMinChoicesController)
  }
}

registerControllers()
document.addEventListener("turbo:load", registerControllers, { once: true })
document.addEventListener("DOMContentLoaded", registerControllers, { once: true })
