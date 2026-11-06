import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get values() { return { required: Boolean } }

  connect() {
    if (!this.requiredValue) return
    this.boundValidate = this.validate.bind(this)
    this.element.addEventListener("change", this.boundValidate)

    this.form = this.element.closest("form")
    this.boundPreventSubmit = this.preventSubmit.bind(this)
    this.form?.addEventListener("submit", this.boundPreventSubmit)
  }

  disconnect() {
    this.element.removeEventListener("change", this.boundValidate)
    this.form?.removeEventListener("submit", this.boundPreventSubmit)
  }

  validate() {
    this.groupElements().forEach((groupEl) => {
      const anyChecked = Array.from(groupEl.querySelectorAll("input[type='checkbox']"))
        .some((cb) => cb.checked)
      groupEl.querySelector(".group-one-required-alert")
        ?.style.setProperty("display", anyChecked ? "none" : "")
    })
  }

  preventSubmit(event) {
    const invalid = this.groupElements().some((groupEl) =>
      Array.from(groupEl.querySelectorAll("input[type='checkbox']")).every((cb) => !cb.checked)
    )
    if (invalid) {
      event.preventDefault()
      this.validate()
    }
  }

  groupElements() {
    return Array.from(this.element.querySelectorAll("[data-group-id]"))
  }
}
