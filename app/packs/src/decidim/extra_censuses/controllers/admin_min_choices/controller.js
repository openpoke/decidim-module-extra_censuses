import { Controller } from "@hotwired/stimulus"

const MIN_WRAPPER = ".questionnaire-question-min-choices"
const MAX_WRAPPER = ".questionnaire-question-max-choices"
const RESPONSE_OPTION = ".questionnaire-question-response-option"
const QUESTION_TYPE = "select[name$='[question_type]']"
const ALLOWED_QUESTION_TYPE = "multiple_option"
const OBSERVER_CONFIG = { subtree: true, childList: true, attributes: true, attributeFilter: ["class"] }

export default class extends Controller {
  connect() {
    this.minSelect = this.element.querySelector(`${MIN_WRAPPER} select`)
    this.maxSelect = this.element.querySelector(`${MAX_WRAPPER} select`)
    this.typeSelect = this.element.querySelector(QUESTION_TYPE)
    this.minWrapper = this.element.querySelector(MIN_WRAPPER)
    if (!this.minSelect) {
      return
    }

    this.boundOnMaxChange = this.onMaxChange.bind(this)
    this.boundSyncAll = this.syncAll.bind(this)
    this.boundSyncVisibility = this.syncVisibility.bind(this)

    this.lastMaxValue = this.maxSelect?.value || ""
    this.maxSelect?.addEventListener("change", this.boundOnMaxChange)
    this.typeSelect?.addEventListener("change", this.boundSyncVisibility)

    this.observer = new MutationObserver(this.boundSyncAll)
    this.observer.observe(this.element, OBSERVER_CONFIG)

    this.syncAll()
    this.syncVisibility()
  }

  disconnect() {
    this.maxSelect?.removeEventListener("change", this.boundOnMaxChange)
    this.typeSelect?.removeEventListener("change", this.boundSyncVisibility)
    this.observer?.disconnect()
  }

  onMaxChange() {
    this.lastMaxValue = this.maxSelect.value
    this.populateMin()
  }

  syncAll() {
    if (this.syncing) {
      return
    }
    this.syncing = true
    try {
      this.populateMax()
      this.populateMin()
    } finally {
      queueMicrotask(() => {
        this.syncing = false
      })
    }
  }

  populateMax() {
    this.populateRange(this.maxSelect, { from: 2, to: this.liveOptionsCount(), restore: this.lastMaxValue })
  }

  populateMin() {
    const selected = Number(this.maxSelect?.value)
    const upperBound = selected > 0
      ? selected
      : this.liveOptionsCount()
    this.populateRange(this.minSelect, { from: 1, to: upperBound, restore: this.minSelect.value })
  }

  populateRange(select, { from, to, restore }) {
    if (!select) {
      return
    }
    select.querySelectorAll("option:not([value=''])").forEach((opt) => opt.remove())
    for (let idx = from; idx <= to; idx += 1) {
      const opt = document.createElement("option")
      opt.value = String(idx)
      opt.textContent = String(idx)
      select.appendChild(opt)
    }
    if (restore && Number(restore) <= to) {
      select.value = restore
    }
  }

  liveOptionsCount() {
    return this.element.querySelectorAll(`${RESPONSE_OPTION}:not(.hidden)`).length
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
