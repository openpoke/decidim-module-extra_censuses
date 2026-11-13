import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
    return ["exclusive"]
  }

  connect() {
    this.exclusiveInput = this.exclusiveTarget.querySelector("input[type=checkbox]")
    if (!this.exclusiveInput) {
      return
    }

    this.boundRender = this.render.bind(this)
    this.exclusiveInput.addEventListener("change", this.boundRender)
    this.render()
  }

  disconnect() {
    this.exclusiveInput?.removeEventListener("change", this.boundRender)
  }

  render() {
    const selected = this.exclusiveInput.checked
    this.otherInputs().forEach((input) => {
      if (selected) {
        input.checked = false
      }
      input.disabled = selected
    })
  }

  otherInputs() {
    return Array.from(this.element.querySelectorAll("input[type=checkbox]")).filter((input) => input !== this.exclusiveInput)
  }
}
