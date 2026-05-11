import { Controller } from "@hotwired/stimulus"

const MIN_WRAPPER = ".questionnaire-question-min-choices"
const MAX_WRAPPER = ".questionnaire-question-max-choices"
const RESPONSE_OPTION = ".questionnaire-question-response-option"
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

    this.boundSyncAll = this.syncAll.bind(this)
    this.boundSyncVisibility = this.syncVisibility.bind(this)
    this.boundCacheMaxValue = this.cacheMaxValue.bind(this)

    if (this.maxSelect) {
      this.lastMaxValue = this.maxSelect.value
      this.maxSelect.addEventListener("change", this.boundCacheMaxValue)
    }
    this.typeSelect?.addEventListener("change", this.boundSyncVisibility)

    // Single source of truth: the count of live response options in the
    // question card. Both upstream add/remove and our group-aware add/remove
    // mutate the same subtree, so we react to that instead of the max_choices
    // select itself.
    this.optionsObserver = new MutationObserver(this.boundSyncAll)
    this.startObservingOptions()

    this.syncAll()
    this.syncVisibility()
  }

  startObservingOptions() {
    this.optionsObserver.observe(this.element, {
      subtree: true,
      childList: true,
      attributes: true,
      attributeFilter: ["class"]
    })
  }

  disconnect() {
    this.maxSelect?.removeEventListener("change", this.boundCacheMaxValue)
    this.typeSelect?.removeEventListener("change", this.boundSyncVisibility)
    this.optionsObserver?.disconnect()
  }

  cacheMaxValue() {
    this.lastMaxValue = this.maxSelect.value
    this.syncMinOptions()
  }

  syncAll() {
    // Detach while we mutate the selects so we don't observe our own writes.
    this.optionsObserver?.disconnect()
    this.syncMaxOptions()
    this.syncMinOptions()
    this.startObservingOptions()
  }

  syncMaxOptions() {
    if (!this.maxSelect) {
      return
    }
    const liveCount = this.element.querySelectorAll(`${RESPONSE_OPTION}:not(.hidden)`).length
    this.maxSelect.querySelectorAll("option:not([value=''])").forEach((opt) => opt.remove())
    for (let idx = 2; idx <= liveCount; idx += 1) {
      const opt = document.createElement("option")
      opt.value = String(idx)
      opt.textContent = String(idx)
      this.maxSelect.appendChild(opt)
    }
    if (this.lastMaxValue && Number(this.lastMaxValue) <= liveCount) {
      this.maxSelect.value = this.lastMaxValue
    }
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
