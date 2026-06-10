import { Controller } from "@hotwired/stimulus"

const QUESTION_TYPE_SELECT = "select[name$='[question_type]']"
const BORDA_WRAPPER = ".questionnaire-question-borda"
const MULTIPLE_OPTION = "multiple_option"

export default class extends Controller {
  static get targets() {
    return ["checkbox", "scoringScale", "scoringScaleWrapper"]
  }

  connect() {
    this.bordaWrapper = this.element.querySelector(BORDA_WRAPPER)
    if (!this.bordaWrapper || !this.hasCheckboxTarget) {
      return
    }

    this.typeSelect = this.element.querySelector(QUESTION_TYPE_SELECT)
    this.frozen = this.checkboxTarget.dataset.adminBordaFrozen === "true"

    this.boundOnContextChange = this.onContextChange.bind(this)
    this.boundOnToggle = this.onToggle.bind(this)

    this.typeSelect?.addEventListener("change", this.boundOnContextChange)
    this.checkboxTarget.addEventListener("change", this.boundOnToggle)

    this.syncWrapperVisibility()
    this.syncScoringScaleVisibility()
  }

  disconnect() {
    this.typeSelect?.removeEventListener("change", this.boundOnContextChange)
    this.checkboxTarget?.removeEventListener("change", this.boundOnToggle)
  }

  onContextChange() {
    if (this.frozen) {
      return
    }
    if (!this.isMultipleOption() && this.checkboxTarget.checked) {
      this.checkboxTarget.checked = false
    }
    this.syncWrapperVisibility()
    this.syncScoringScaleVisibility()
  }

  onToggle() {
    this.syncScoringScaleVisibility()
  }

  syncWrapperVisibility() {
    this.bordaWrapper.classList.toggle("hidden", !this.isMultipleOption())
  }

  syncScoringScaleVisibility() {
    const visible = this.checkboxTarget.checked
    if (this.hasScoringScaleWrapperTarget) {
      this.scoringScaleWrapperTarget.classList.toggle("hidden", !visible)
    }
    if (!visible && this.hasScoringScaleTarget && !this.frozen) {
      this.scoringScaleTarget.value = "start_from_max"
    }
  }

  isMultipleOption() {
    return !this.typeSelect || this.typeSelect.value === MULTIPLE_OPTION
  }
}
