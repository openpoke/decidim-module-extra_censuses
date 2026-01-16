import { Controller } from "@hotwired/stimulus"

/**
 * Stimulus controller for Custom CSV Census column builder.
 *
 * Handles dynamic column management for census configuration:
 * - Adding/removing columns
 * - Syncing visible inputs with hidden form fields
 * - Toggling between edit and upload modes
 */
export default class extends Controller {
  connect() {
    this.formPrefix = this.element.dataset.customCsvCensusFormPrefixValue
    this.configured = this.element.dataset.customCsvCensusConfiguredValue === "true"
    this.buttonText = this.element.dataset.customCsvCensusButtonTextValue
    this.originalButtonText = this.stickyButton?.textContent || ""
    this.editInitialized = false

    if (!this.configured) {
      this.updateHiddenFields()
      this.updateStickyButtonText(this.buttonText)
    }
  }

  get columnsList() {
    return this.element.querySelector("[data-custom-csv-census-target='columnsList']")
  }

  get hiddenFields() {
    return this.element.querySelector("[data-custom-csv-census-target='hiddenFields']")
  }

  get editorSection() {
    return this.element.querySelector("[data-custom-csv-census-target='editorSection']")
  }

  get uploadSection() {
    return this.element.querySelector("[data-custom-csv-census-target='uploadSection']")
  }

  get stickyButton() {
    return document.querySelector(".item__edit-sticky button[form='census-election-form']")
  }

  /**
   * Add a new column row from template
   * @param {Event} event - Click event
   * @returns {void}
   */
  addColumn(event) {
    event.preventDefault()
    const template = document.getElementById("column-row-template")
    const row = template.content.firstElementChild.cloneNode(true)
    this.columnsList.appendChild(row)
    this.updateHiddenFields()
  }

  /**
   * Remove a column row
   * @param {Event} event - Click event
   * @returns {void}
   */
  removeColumn(event) {
    event.preventDefault()
    const row = event.target.closest("[data-column-row]")
    if (row) {
      row.remove()
      this.updateHiddenFields()
    }
  }

  /**
   * Update hidden fields when column data changes
   * @returns {void}
   */
  updateHiddenFields() {
    const hiddenFieldsEl = this.hiddenFields
    if (!hiddenFieldsEl) {
      return
    }

    hiddenFieldsEl.innerHTML = ""

    this.columnsList.querySelectorAll("[data-column-row]").forEach((row, index) => {
      const name = row.querySelector(".column-name").value.trim()
      const type = row.querySelector(".column-type").value

      hiddenFieldsEl.appendChild(
        this.createHiddenInput(`${this.formPrefix}[columns][${index}][name]`, name)
      )
      hiddenFieldsEl.appendChild(
        this.createHiddenInput(`${this.formPrefix}[columns][${index}][column_type]`, type)
      )
    })
  }

  /**
   * Toggle between edit and upload modes (configured mode only)
   * @param {Event} event - Click event
   * @returns {void}
   */
  toggleEdit(event) {
    event.preventDefault()

    const isHidden = this.editorSection.classList.contains("hidden")

    this.editorSection.classList.toggle("hidden", !isHidden)
    this.uploadSection.classList.toggle("hidden", isHidden)

    if (isHidden) {
      // Switching to edit mode
      this.toggleUploadRequired(false)
      this.clearUploadedFiles()
      this.updateStickyButtonText(this.buttonText)

      if (!this.editInitialized) {
        this.updateHiddenFields()
        this.editInitialized = true
      }
    } else {
      // Switching to upload mode
      this.toggleUploadRequired(true)
      this.updateStickyButtonText(this.originalButtonText)
    }
  }

  createHiddenInput(name, value) {
    const input = document.createElement("input")
    input.type = "hidden"
    input.name = name
    input.value = value
    return input
  }

  clearUploadedFiles() {
    const form = document.getElementById("census-election-form")
    if (!form) {
      return
    }

    form.querySelectorAll("input[type='file']").forEach((input) => {
      input.value = ""
    })
    form.querySelectorAll("[data-active-uploads]").forEach((container) => {
      container.innerHTML = ""
    })
    form.querySelectorAll("input[type='hidden'][name*='[file]']").forEach((input) => {
      input.remove()
    })
  }

  toggleUploadRequired(required) {
    const uploadSection = this.uploadSection
    if (!uploadSection) {
      return
    }

    uploadSection.querySelectorAll("input[required], input[data-required]").forEach((input) => {
      if (required && input.dataset.wasRequired === "true") {
        input.setAttribute("required", "required")
      } else if (!required && input.hasAttribute("required")) {
        input.dataset.wasRequired = "true"
        input.removeAttribute("required")
      }
    })
  }

  updateStickyButtonText(text) {
    if (this.stickyButton && text) {
      this.stickyButton.textContent = text
    }
  }
}
