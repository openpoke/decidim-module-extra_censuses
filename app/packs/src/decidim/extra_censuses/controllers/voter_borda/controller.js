import { Controller } from "@hotwired/stimulus"

// Voter-facing ranked (BORDA) ballot. Maintains a client-side
// { optionId => position } map that is always contiguous {1..count}, mirrors it
// into the per-option position <select>, and derives the submit button and the
// limit hint purely from the selection count. No `required` attributes, so a
// no-JS ballot still submits and relies on the server-side contiguity/range
// validation.
export default class extends Controller {
  static get targets() {
    return ["checkbox", "position", "counter", "limitHint"]
  }

  static get values() {
    return {
      minChoices: Number,
      maxChoices: Number,
      scoringScale: String,
      ordinals: Array,
      labelOne: String,
      labelOther: String
    }
  }

  connect() {
    if (this.scoringScaleValue === "") {
      return
    }

    this.ranks = {}
    this.checkboxTargets.forEach((checkbox) => {
      const optionId = checkbox.dataset.optionId
      const select = this.positionFor(optionId)
      const stored = select && select.value !== ""
        ? parseInt(select.value, 10)
        : null
      if (checkbox.checked && stored) {
        this.ranks[optionId] = stored
      }
    })

    this.normalize()

    this.boundOnCheckbox = this.onCheckbox.bind(this)
    this.boundOnSelect = this.onSelect.bind(this)
    this.checkboxTargets.forEach((checkbox) => checkbox.addEventListener("change", this.boundOnCheckbox))
    this.positionTargets.forEach((select) => select.addEventListener("change", this.boundOnSelect))

    this.render()
  }

  disconnect() {
    this.checkboxTargets.forEach((checkbox) => checkbox.removeEventListener("change", this.boundOnCheckbox))
    this.positionTargets.forEach((select) => select.removeEventListener("change", this.boundOnSelect))
  }

  get count() {
    return Object.keys(this.ranks).length
  }

  onCheckbox(event) {
    const optionId = event.target.dataset.optionId
    if (event.target.checked) {
      if (this.count >= this.maxChoicesValue) {
        event.target.checked = false
        return
      }
      this.ranks[optionId] = this.count + 1
    } else {
      this.removeRank(optionId)
    }
    this.render()
  }

  onSelect(event) {
    const optionId = event.target.dataset.optionId
    const oldRank = this.ranks[optionId]
    const newRank = parseInt(event.target.value, 10)
    if (!oldRank || Number.isNaN(newRank) || newRank === oldRank) {
      this.render()
      return
    }

    if (newRank < oldRank) {
      Object.keys(this.ranks).forEach((id) => {
        if (id !== optionId && this.ranks[id] >= newRank && this.ranks[id] <= oldRank - 1) {
          this.ranks[id] += 1
        }
      })
    } else {
      Object.keys(this.ranks).forEach((id) => {
        if (id !== optionId && this.ranks[id] >= oldRank + 1 && this.ranks[id] <= newRank) {
          this.ranks[id] -= 1
        }
      })
    }
    this.ranks[optionId] = newRank
    this.render()
  }

  removeRank(optionId) {
    const removed = this.ranks[optionId]
    Reflect.deleteProperty(this.ranks, optionId)
    Object.keys(this.ranks).forEach((id) => {
      if (this.ranks[id] > removed) {
        this.ranks[id] -= 1
      }
    })
  }

  // Repairs any non-contiguous state inherited from a pre-rendered ballot.
  normalize() {
    const ordered = Object.keys(this.ranks).sort((first, second) => this.ranks[first] - this.ranks[second])
    ordered.forEach((id, index) => {
      this.ranks[id] = index + 1
    })
  }

  render() {
    const count = this.count
    this.checkboxTargets.forEach((checkbox) => {
      const optionId = checkbox.dataset.optionId
      const select = this.positionFor(optionId)
      const ranked = Reflect.has(this.ranks, optionId)

      checkbox.checked = ranked
      checkbox.disabled = !ranked && count >= this.maxChoicesValue

      if (!select) {
        return
      }
      select.disabled = !ranked
      select.style.display = ranked
        ? ""
        : "none"
      this.fillSelect(select, count)
      select.value = ranked
        ? String(this.ranks[optionId])
        : ""
    })

    this.renderCounter(count)
    this.renderSubmit(count)
  }

  fillSelect(select, count) {
    const size = count > 0
      ? count
      : this.maxChoicesValue
    const previous = select.value
    select.innerHTML = ""
    const blank = document.createElement("option")
    blank.value = ""
    select.appendChild(blank)
    for (let position = 1; position <= size; position += 1) {
      const option = document.createElement("option")
      option.value = String(position)
      option.textContent = this.labelFor(position, size)
      select.appendChild(option)
    }
    select.value = previous
  }

  labelFor(position, ballotSize) {
    const points = this.scoringScaleValue === "start_from_min"
      ? ballotSize - position + 1
      : this.maxChoicesValue - position + 1
    const ordinal = this.ordinalsValue[position - 1] || String(position)
    const template = points === 1
      ? this.labelOneValue
      : this.labelOtherValue
    return template.replace("%{ordinal}", ordinal).replace("%{count}", String(points))
  }

  renderCounter(count) {
    if (!this.hasCounterTarget) {
      return
    }
    this.counterTarget.textContent = `selected ${count} / ${this.maxChoicesValue}`
    if (this.hasLimitHintTarget) {
      this.limitHintTarget.style.display = count >= this.maxChoicesValue
        ? "block"
        : "none"
    }
  }

  renderSubmit(count) {
    const submit = this.submitButton()
    if (!submit) {
      return
    }
    submit.disabled = count < this.minChoicesValue || count > this.maxChoicesValue
  }

  positionFor(optionId) {
    return this.positionTargets.find((select) => select.dataset.optionId === optionId)
  }

  submitButton() {
    const form = this.element.closest("form")
    return form
      ? form.querySelector("button[type=submit]")
      : null
  }
}
