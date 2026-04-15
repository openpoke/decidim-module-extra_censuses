import { Controller } from "@hotwired/stimulus"

const QUESTION_TYPE_SELECT = "select[name$='[question_type]']"
const GROUPED_CHECKBOX = "input[type='checkbox'][name$='[grouped]']"
const CHECKBOX_WRAPPER = ".questionnaire-question-grouped"
const GROUPS_SECTION = ".questionnaire-question-groups"
const FLAT_LIST = "[data-extra-censuses-flat-list]"
const FLAT_ADD_BUTTON = ".add-response-option"
const MULTIPLE_OPTION = "multiple_option"
const TOGGLE_EVENT = "grouped-question-toggle:change"

export default class extends Controller {
  connect() {
    this.typeSelect = this.element.querySelector(QUESTION_TYPE_SELECT)
    this.checkbox = this.element.querySelector(GROUPED_CHECKBOX)
    if (!this.typeSelect || !this.checkbox) return

    this.checkboxWrapper = this.checkbox.closest(CHECKBOX_WRAPPER)
    this.groupsSection = this.element.querySelector(GROUPS_SECTION)
    this.flatList = this.element.querySelector(FLAT_LIST)
    this.flatSection = this.flatList?.parentElement
    this.flatAddRow = this.flatSection?.querySelector(FLAT_ADD_BUTTON)?.closest(".row")
    this.previousGrouped = this.checkbox.checked

    this.boundOnTypeChange = this.onTypeChange.bind(this)
    this.boundOnToggle = this.onToggle.bind(this)
    this.typeSelect.addEventListener("change", this.boundOnTypeChange)
    this.checkbox.addEventListener("change", this.boundOnToggle)

    this.syncCheckboxVisibility()
    this.syncSectionVisibility(this.previousGrouped)
  }

  disconnect() {
    this.typeSelect?.removeEventListener("change", this.boundOnTypeChange)
    this.checkbox?.removeEventListener("change", this.boundOnToggle)
  }

  onTypeChange() {
    if (this.typeSelect.value !== MULTIPLE_OPTION && this.checkbox.checked) {
      this.checkbox.checked = false
      this.onToggle()
    }
    this.syncCheckboxVisibility()
  }

  onToggle() {
    const grouped = this.checkbox.checked
    const wasGrouped = this.previousGrouped
    this.previousGrouped = grouped
    this.syncSectionVisibility(grouped)
    this.groupsSection?.dispatchEvent(new CustomEvent(TOGGLE_EVENT, { detail: { grouped, wasGrouped } }))
  }

  syncCheckboxVisibility() {
    this.checkboxWrapper?.classList.toggle("hidden", this.typeSelect.value !== MULTIPLE_OPTION)
  }

  syncSectionVisibility(grouped) {
    this.groupsSection?.classList.toggle("hidden", !grouped)
    this.flatSection?.classList.toggle("hidden", grouped)
    this.flatAddRow?.classList.toggle("hidden", grouped)
  }
}
