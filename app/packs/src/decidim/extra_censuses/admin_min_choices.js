import { Controller } from "@hotwired/stimulus"

const MIN_WRAPPER = ".questionnaire-question-min-choices"
const MAX_WRAPPER = ".questionnaire-question-max-choices"
const QUESTION_TYPE = "select[name$='[question_type]']"
const MULTIPLE_OPTION = "multiple_option"

/**
 * Keeps the min_choices select in sync with max_choices and question_type
 * on the admin question form.
 */
export default class extends Controller {
  connect() {
    this.minSelect = this.element.querySelector(`${MIN_WRAPPER} select`)
    this.maxSelect = this.element.querySelector(`${MAX_WRAPPER} select`)
    this.typeSelect = this.element.querySelector(QUESTION_TYPE)
    this.minWrapper = this.element.querySelector(MIN_WRAPPER)

    if (!this.minSelect) {
      return
    }

    this.abortController = new AbortController()
    const { signal } = this.abortController

    if (this.maxSelect) {
      this.maxSelect.addEventListener("change", () => this.syncMinOptions(), { signal })
      // Watch max_choices <option> list: Decidim rebuilds it when response options are added/removed,
      // so this also covers reacting to response option changes.
      this.maxOptionsObserver = new MutationObserver(() => this.syncMinOptions())
      this.maxOptionsObserver.observe(this.maxSelect, { childList: true })
    }
    if (this.typeSelect) {
      this.typeSelect.addEventListener("change", () => this.syncVisibility(), { signal })
    }

    this.syncMinOptions()
    this.syncVisibility()
  }

  disconnect() {
    this.abortController?.abort()
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

    if (values.length) {
      return Math.max(...values)
    }

    return 0
  }

  syncVisibility() {
    if (!this.typeSelect || !this.minWrapper) {
      return
    }

    const isMultiple = this.typeSelect.value === MULTIPLE_OPTION
    this.minWrapper.classList.toggle("hidden", !isMultiple)
    this.minSelect.disabled = !isMultiple
    if (!isMultiple) {
      this.minSelect.value = ""
    }
  }
}
