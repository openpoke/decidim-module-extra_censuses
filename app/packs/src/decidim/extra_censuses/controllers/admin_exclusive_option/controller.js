import { Controller } from "@hotwired/stimulus"

const QUESTION_TYPE_SELECT = "select[name$='[question_type]']"
const BORDA_CHECKBOX = "[data-admin-borda-target='checkbox']"
const MULTIPLE_OPTION = "multiple_option"

export default class extends Controller {
  static get targets() {
    return ["wrapper", "checkbox", "body"]
  }

  connect() {
    if (!this.hasCheckboxTarget) {
      return
    }

    this.typeSelect = this.element.querySelector(QUESTION_TYPE_SELECT)
    this.bordaCheckbox = this.element.querySelector(BORDA_CHECKBOX)
    this.frozen = this.checkboxTarget.dataset.adminExclusiveOptionFrozen === "true"

    this.boundOnContextChange = this.onContextChange.bind(this)
    this.boundSyncBodyVisibility = this.syncBodyVisibility.bind(this)

    this.typeSelect?.addEventListener("change", this.boundOnContextChange)
    this.bordaCheckbox?.addEventListener("change", this.boundOnContextChange)
    this.checkboxTarget.addEventListener("change", this.boundSyncBodyVisibility)

    this.syncWrapperVisibility()
    this.syncBodyVisibility()
  }

  disconnect() {
    this.typeSelect?.removeEventListener("change", this.boundOnContextChange)
    this.bordaCheckbox?.removeEventListener("change", this.boundOnContextChange)
    this.checkboxTarget?.removeEventListener("change", this.boundSyncBodyVisibility)
  }

  onContextChange() {
    if (this.frozen) {
      return
    }
    if (!this.isAllowed() && this.checkboxTarget.checked) {
      this.checkboxTarget.checked = false
    }
    this.syncWrapperVisibility()
    this.syncBodyVisibility()
  }

  syncWrapperVisibility() {
    if (this.hasWrapperTarget) {
      this.wrapperTarget.classList.toggle("hidden", !this.isAllowed())
    }
  }

  syncBodyVisibility() {
    if (this.hasBodyTarget) {
      this.bodyTarget.classList.toggle("hidden", !this.checkboxTarget.checked)
    }
  }

  isAllowed() {
    const multipleOption = !this.typeSelect || this.typeSelect.value === MULTIPLE_OPTION
    const borda = Boolean(this.bordaCheckbox?.checked)
    return multipleOption && !borda
  }
}
