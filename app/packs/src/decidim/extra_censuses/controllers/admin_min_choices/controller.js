import { Controller } from "@hotwired/stimulus"

const MIN_WRAPPER = ".questionnaire-question-min-choices"
const MAX_WRAPPER = ".questionnaire-question-max-choices"
const QUESTION_TYPE = "select[name$='[question_type]']"
const ALLOWED_QUESTION_TYPE = "multiple_option"

export default class extends Controller {
  connect() {
    this.minSelect = this.element.querySelector(`${MIN_WRAPPER} select`)
    this.maxSelect = this.element.querySelector(`${MAX_WRAPPER} select`)
    this.typeSelect = this.element.querySelector(QUESTION_TYPE)
    this.minWrapper = this.element.querySelector(MIN_WRAPPER)
    if (!this.minSelect) {
      return
    }

    this.boundSyncMinOptions = this.syncMinOptions.bind(this)
    this.boundSyncVisibility = this.syncVisibility.bind(this)

    if (this.maxSelect) {
      this.maxSelect.addEventListener("change", this.boundSyncMinOptions)
      // Upstream rebuilds max_choices <option> when response options change.
      this.maxOptionsObserver = new MutationObserver(this.boundSyncMinOptions)
      this.maxOptionsObserver.observe(this.maxSelect, { childList: true })
    }
    this.typeSelect?.addEventListener("change", this.boundSyncVisibility)

    this.syncMinOptions()
    this.syncVisibility()
  }

  disconnect() {
    this.maxSelect?.removeEventListener("change", this.boundSyncMinOptions)
    this.typeSelect?.removeEventListener("change", this.boundSyncVisibility)
    this.maxOptionsObserver?.disconnect()
  }

  syncMinOptions() {
    const upperBound = this.computeUpperBound()
    const currentValue = this.minSelect.value
    this.minSelect.querySelectorAll("option:not([value=''])").forEach((opt) => opt.remove())
    if (upperBound < 1) {
      return
    }

    for (let idx = 1; idx <= upperBound; idx += 1) {
      const opt = document.createElement("option")
      opt.value = String(idx)
      opt.textContent = String(idx)
      this.minSelect.appendChild(opt)
    }
    if (currentValue && Number(currentValue) <= upperBound) {
      this.minSelect.value = currentValue
    }
  }

  computeUpperBound() {
    if (!this.maxSelect) {
      return 0
    }
    const selected = Number(this.maxSelect.value)
    if (selected > 0) {
      return selected
    }
    const values = Array.from(this.maxSelect.options).
      map((opt) => Number(opt.value)).
      filter((num) => num > 0)
    if (values.length === 0) {
      return 0
    }
    return Math.max(...values)
  }

  syncVisibility() {
    if (!this.typeSelect || !this.minWrapper) {
      return
    }
    const isAllowed = this.typeSelect.value === ALLOWED_QUESTION_TYPE
    this.minWrapper.classList.toggle("hidden", !isAllowed)
    this.minSelect.disabled = !isAllowed
    if (!isAllowed) {
      this.minSelect.value = ""
    }
  }
}
