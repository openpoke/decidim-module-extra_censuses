import CustomCsvCensusController from "src/decidim/extra_censuses/controllers/custom_csv_census_controller"
import SurveyImportController from "src/decidim/extra_censuses/controllers/survey_import_controller"
import AdminMinChoicesController from "src/decidim/extra_censuses/controllers/admin_min_choices/controller"
import AdminBordaController from "src/decidim/extra_censuses/controllers/admin_borda/controller"
import AdminExclusiveOptionController from "src/decidim/extra_censuses/controllers/admin_exclusive_option/controller"
import VoterBordaController from "src/decidim/extra_censuses/controllers/voter_borda/controller"
import GroupedQuestionToggleController from "src/decidim/extra_censuses/controllers/grouped_question_toggle/controller"
import ResponseOptionGroupsController from "src/decidim/extra_censuses/controllers/response_option_groups/controller"
import ResponseOptionGroupController from "src/decidim/extra_censuses/controllers/response_option_group/controller"
import WinnersToggleController from "src/decidim/extra_censuses/controllers/winners_toggle/controller"
import ResultsSorterController from "src/decidim/extra_censuses/controllers/results_sorter/controller"
import GroupedVoteValidationController from "src/decidim/extra_censuses/controllers/grouped_vote_validation/controller"
import VoterExclusiveOptionController from "src/decidim/extra_censuses/controllers/voter_exclusive_option/controller"

let registered = false

document.addEventListener("turbo:load", () => {
  if (registered || !window.Stimulus) {
    return
  }
  
  window.Stimulus.register("custom-csv-census", CustomCsvCensusController)
  window.Stimulus.register("survey-import", SurveyImportController)
  window.Stimulus.register("admin-min-choices", AdminMinChoicesController)
  window.Stimulus.register("admin-borda", AdminBordaController)
  window.Stimulus.register("admin-exclusive-option", AdminExclusiveOptionController)
  window.Stimulus.register("voter-borda", VoterBordaController)
  window.Stimulus.register("grouped-question-toggle", GroupedQuestionToggleController)
  window.Stimulus.register("response-option-groups", ResponseOptionGroupsController)
  window.Stimulus.register("response-option-group", ResponseOptionGroupController)
  window.Stimulus.register("winners-toggle", WinnersToggleController)
  window.Stimulus.register("results-sorter", ResultsSorterController)
  window.Stimulus.register("grouped-vote-validation", GroupedVoteValidationController)
  window.Stimulus.register("voter-exclusive-option", VoterExclusiveOptionController)

  registered = true
})
