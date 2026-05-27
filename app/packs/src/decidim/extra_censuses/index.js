import CustomCsvCensusController from "src/decidim/extra_censuses/controllers/custom_csv_census_controller"
import SurveyImportController from "src/decidim/extra_censuses/controllers/survey_import_controller"
import AdminMinChoicesController from "src/decidim/extra_censuses/controllers/admin_min_choices/controller"
import AdminBordaController from "src/decidim/extra_censuses/controllers/admin_borda/controller"
import GroupedQuestionToggleController from "src/decidim/extra_censuses/controllers/grouped_question_toggle/controller"
import ResponseOptionGroupsController from "src/decidim/extra_censuses/controllers/response_option_groups/controller"
import ResponseOptionGroupController from "src/decidim/extra_censuses/controllers/response_option_group/controller"

let registered = false

document.addEventListener("turbo:load", () => {
  if (registered || !window.Stimulus) {
    return
  }

  window.Stimulus.register("custom-csv-census", CustomCsvCensusController)
  window.Stimulus.register("survey-import", SurveyImportController)
  window.Stimulus.register("admin-min-choices", AdminMinChoicesController)
  window.Stimulus.register("admin-borda", AdminBordaController)
  window.Stimulus.register("grouped-question-toggle", GroupedQuestionToggleController)
  window.Stimulus.register("response-option-groups", ResponseOptionGroupsController)
  window.Stimulus.register("response-option-group", ResponseOptionGroupController)

  registered = true
})
