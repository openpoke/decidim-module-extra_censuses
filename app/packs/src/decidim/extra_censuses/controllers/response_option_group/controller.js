import { Controller } from "@hotwired/stimulus"

const TITLE_STATEMENT = ".group-title-statement"
const CONTENT = ".group-response-options"
const ICON_COLLAPSE = ".group-icon-collapse"
const ICON_EXPAND = ".group-icon-expand"

export default class extends Controller {
  connect() {
    this.titleStatement = this.element.querySelector(TITLE_STATEMENT)
    this.titleInput = this.findTitleInput()

    if (this.titleInput) {
      this.boundUpdateLabel = this.updateLabel.bind(this)
      this.titleInput.addEventListener("input", this.boundUpdateLabel)
      this.titleInput.addEventListener("change", this.boundUpdateLabel)
    }
    this.updateLabel()
  }

  disconnect() {
    if (this.titleInput && this.boundUpdateLabel) {
      this.titleInput.removeEventListener("input", this.boundUpdateLabel)
      this.titleInput.removeEventListener("change", this.boundUpdateLabel)
    }
  }

  toggleCollapse(event) {
    event.preventDefault()
    const button = event.currentTarget
    const willExpand = button.getAttribute("aria-expanded") === "false"
    button.setAttribute("aria-expanded", willExpand.toString())
    this.element.querySelector(CONTENT)?.classList.toggle("hidden", !willExpand)
    button.querySelector(ICON_COLLAPSE)?.classList.toggle("hidden", !willExpand)
    button.querySelector(ICON_EXPAND)?.classList.toggle("hidden", willExpand)
  }

  updateLabel() {
    if (!this.titleStatement) {
      return
    }
    const maxLength = parseInt(this.titleStatement.dataset.maxLength, 10) || 50
    const omission = this.titleStatement.dataset.omission || "..."
    const placeholder = this.titleStatement.dataset.placeholder || ""
    let text = (this.titleInput && this.titleInput.value) || placeholder
    if (text.length > maxLength) {
      text = text.substring(0, maxLength - omission.length) + omission
    }
    this.titleStatement.textContent = text
  }

  findTitleInput() {
    const locale = this.titleStatement?.dataset.locale
    if (!locale) {
      return null
    }
    return this.element.querySelector(`input[name$='[title_${locale}]']`)
  }
}
