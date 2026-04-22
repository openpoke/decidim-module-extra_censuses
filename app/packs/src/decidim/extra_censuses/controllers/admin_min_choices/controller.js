import { Controller } from "@hotwired/stimulus"

const MIN_WRAPPER = ".questionnaire-question-min-choices"
const MAX_WRAPPER = ".questionnaire-question-max-choices"
const QUESTION_TYPE = "select[name$='[question_type]']"
const ALLOWED_QUESTION_TYPE = "multiple_option"
const RESPONSE_OPTION = ".questionnaire-question-response-option"

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
    this.boundSyncMaxOptions = this.syncMaxOptions.bind(this)

    if (this.maxSelect) {
      this.maxSelect.addEventListener("change", this.boundSyncMinOptions)
    }
    this.typeSelect?.addEventListener("change", this.boundSyncVisibility)

    // Rebuild max_choices options whenever response options are added, removed,
    // or soft-deleted (hidden class toggled). The override replaces the upstream
    // dynamic select with a server-rendered static one, so we own the update.
    // We filter mutations so that changes to maxSelect's own <option> children
    // (caused by syncMaxOptions itself) do not trigger a re-entrant call.
    this.responseOptionsObserver = new MutationObserver((mutations) => {
      const relevant = mutations.some((m) => {
        if (m.type === "attributes") {
          return m.target.matches?.(RESPONSE_OPTION)
        }
        // childList: check added/removed nodes
        return [...m.addedNodes, ...m.removedNodes].some(
          (n) => n.nodeType === Node.ELEMENT_NODE &&
            (n.matches(RESPONSE_OPTION) || n.querySelector?.(RESPONSE_OPTION))
        )
      })
      if (relevant) {
        this.boundSyncMaxOptions()
      }
    })
    this.responseOptionsObserver.observe(this.element, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ["class"]
    })

    this.syncMaxOptions()
    this.syncVisibility()
  }

  disconnect() {
    this.maxSelect?.removeEventListener("change", this.boundSyncMinOptions)
    this.typeSelect?.removeEventListener("change", this.boundSyncVisibility)
    this.responseOptionsObserver?.disconnect()
  }

  syncMaxOptions() {
    if (!this.maxSelect) {
      return
    }
    const count = this.element.querySelectorAll(`${RESPONSE_OPTION}:not(.hidden)`).length
    const currentValue = this.maxSelect.value
    this.maxSelect.querySelectorAll("option:not([value=''])").forEach((opt) => opt.remove())
    for (let idx = 2; idx <= count; idx += 1) {
      const opt = document.createElement("option")
      opt.value = String(idx)
      opt.textContent = String(idx)
      this.maxSelect.appendChild(opt)
    }
    if (currentValue && Number(currentValue) >= 2 && Number(currentValue) <= count) {
      this.maxSelect.value = currentValue
    }
    this.syncMinOptions()
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