import { Controller } from "@hotwired/stimulus"

/**
 * Stimulus controller for Survey Import.
 *
 * Handles dynamic loading of surveys and questions for census import.
 * - Cascading selects: Component → Survey → Questions
 * - Select all responses checkbox
 */
export default class extends Controller {
  connect() {
    this.surveysUrl = this.componentSelect?.dataset.surveysUrl
    this.questionsUrl = this.surveySelect?.dataset.questionsUrl
  }

  get componentSelect() {
    return this.element.querySelector("[data-survey-import-target='componentSelect']")
  }

  get surveySelect() {
    return this.element.querySelector("[data-survey-import-target='surveySelect']")
  }

  get questionSelects() {
    return this.element.querySelectorAll("[data-survey-import-target='questionSelect']")
  }

  get selectAllCheckbox() {
    return this.element.querySelector("[data-survey-import-target='selectAll']")
  }

  get responseCheckboxes() {
    return this.element.querySelectorAll(".response-checkbox")
  }

  /**
   * Load surveys when component changes
   * @param {Event} event - Change event
   * @returns {void}
   */
  async loadSurveys(event) {
    const componentId = event.target.value

    this.surveySelect.innerHTML = "<option value=''>Loading...</option>"
    this.questionSelects.forEach((select) => {
      select.innerHTML = "<option value=''>Select a question</option>"
    })

    if (!componentId) {
      this.updateSelectOptions(this.surveySelect, [], "Select a survey")
      return
    }

    const surveys = await this.fetchJson(`${this.surveysUrl}?survey_component_id=${componentId}`)
    this.updateSelectOptions(this.surveySelect, surveys, "Select a survey")
  }

  /**
   * Load questions when survey changes
   * @param {Event} event - Change event
   * @returns {void}
   */
  async loadQuestions(event) {
    const surveyId = event.target.value

    this.questionSelects.forEach((select) => {
      select.innerHTML = "<option value=''>Loading...</option>"
    })

    if (!surveyId) {
      this.questionSelects.forEach((select) => {
        select.innerHTML = "<option value=''>Select a question</option>"
      })
      return
    }

    const questions = await this.fetchJson(`${this.questionsUrl}?survey_id=${surveyId}`)
    this.questionSelects.forEach((select) => {
      this.updateSelectOptions(select, questions, "Select a question")
    })
  }

  /**
   * Toggle all response checkboxes
   * @param {Event} event - Change event
   * @returns {void}
   */
  toggleAll(event) {
    const checked = event.target.checked
    this.responseCheckboxes.forEach((checkbox) => {
      checkbox.checked = checked
    })
  }

  async fetchJson(url) {
    try {
      const response = await fetch(url, {
        headers: {
          Accept: "application/json",
          "X-Requested-With": "XMLHttpRequest"
        }
      })
      if (!response.ok) {
        return []
      }
      return response.json()
    } catch (error) {
      console.error("Fetch error:", error)
      return []
    }
  }

  updateSelectOptions(select, options, placeholder) {
    select.innerHTML = ""

    const placeholderOpt = document.createElement("option")
    placeholderOpt.value = ""
    placeholderOpt.textContent = placeholder
    select.appendChild(placeholderOpt)

    options.forEach((option) => {
      const opt = document.createElement("option")
      opt.value = option.id
      opt.textContent = option.title || option.body
      select.appendChild(opt)
    })
  }
}
