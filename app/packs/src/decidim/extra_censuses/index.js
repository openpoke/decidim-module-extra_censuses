import CustomCsvCensusController from "src/decidim/extra_censuses/controllers/custom_csv_census_controller"

const registerControllers = () => {
  if (window.Stimulus) {
    window.Stimulus.register("custom-csv-census", CustomCsvCensusController)
  }
}

registerControllers()
document.addEventListener("turbo:load", registerControllers, { once: true })
document.addEventListener("DOMContentLoaded", registerControllers, { once: true })
