import { Controller } from "@hotwired/stimulus"
import sortable from "html5sortable/dist/html5sortable.es"
import randomId from "src/decidim/extra_censuses/utils/random_id"
import cloneTemplate from "src/decidim/extra_censuses/utils/dom_template"

const TOGGLE_EVENT = "grouped-question-toggle:change"

const GROUP = ".questionnaire-question-group"
const GROUP_OPTIONS_LIST = ".group-response-options-list"
const GROUP_DRAG_HANDLE = ".dragger"
const GROUP_POSITION_LABEL = ".group-position-label"
const OPTION = ".questionnaire-question-response-option"
const FLAT_LIST = "[data-extra-censuses-flat-list]"

const ID_INPUT = "input[name$='[id]']"
const POSITION_INPUT = "input[name$='[position]']"
const DELETED_INPUT = "input[name$='[deleted]']"
const GROUP_ID_INPUT = "input[name$='[group_id]']"

export default class extends Controller {
  static get targets() {
    return ["list", "groupTemplate", "optionTemplate"]
  }

  connect() {
    if (!this.hasListTarget) {
      return
    }

    this.nextUid = 0
    this.flatList = this.findFlatList()

    this.boundResyncPositions = this.resyncPositions.bind(this)
    this.boundOnToggle = this.onToggle.bind(this)
    this.listTarget.addEventListener("sortupdate", this.boundResyncPositions)
    this.element.addEventListener(TOGGLE_EVENT, this.boundOnToggle)

    this.enableSortable()
    this.runAutoLabel()
  }

  disconnect() {
    this.listTarget?.removeEventListener("sortupdate", this.boundResyncPositions)
    this.element.removeEventListener(TOGGLE_EVENT, this.boundOnToggle)
    if (this.hasListTarget) {
      sortable(this.listTarget, "destroy")
    }
  }

  addGroup(event) {
    event.preventDefault()
    const group = this.cloneGroup()
    if (!group) {
      return
    }
    this.listTarget.appendChild(group)
    this.appendOptionTo(group)
    this.enableSortable()
    this.runAutoLabel()
  }

  addOptionInGroup(event) {
    event.preventDefault()
    const group = event.target.closest(GROUP)
    if (group) {
      this.appendOptionTo(group)
    }
  }

  removeGroup(event) {
    event.preventDefault()
    const group = event.target.closest(GROUP)
    if (!group) {
      return
    }
    group.querySelectorAll(OPTION).forEach((option) => this.destroyOrRemove(option))
    this.destroyOrRemove(group)
    this.runAutoLabel()
  }

  removeOption(event) {
    event.preventDefault()
    const option = event.target.closest(OPTION)
    if (option) {
      this.destroyOrRemove(option)
    }
  }

  onToggle(event) {
    const { grouped, wasGrouped } = event.detail
    if (!wasGrouped && grouped) {
      this.wrapFlatOptionsIntoAutoGroup()
    } else if (wasGrouped && !grouped) {
      this.unwrapGroupedOptions()
    }
  }

  wrapFlatOptionsIntoAutoGroup() {
    if (!this.flatList) {
      return
    }
    const flatOptions = Array.from(this.flatList.querySelectorAll(`:scope > ${OPTION}`))
    const group = this.cloneGroup()
    if (!group) {
      return
    }
    this.listTarget.appendChild(group)

    const optionsList = group.querySelector(GROUP_OPTIONS_LIST)
    flatOptions.forEach((option) => {
      this.stampGroupId(option, group.dataset.groupId)
      optionsList?.appendChild(option)
    })
    this.enableSortable()
    this.runAutoLabel()
  }

  // Backend zeroes settings["groups"] and group_id on grouped=false; mirror it.
  unwrapGroupedOptions() {
    if (!this.flatList) {
      return
    }
    this.element.querySelectorAll(OPTION).forEach((option) => {
      this.unstampGroupId(option)
      this.flatList.appendChild(option)
    })
    this.element.querySelectorAll(GROUP).forEach((group) => group.remove())
  }

  cloneGroup() {
    const uid = `new-${this.nextUid}`
    this.nextUid += 1
    const group = cloneTemplate(this.groupTemplateTarget, uid)
    if (!group) {
      return null
    }
    group.dataset.new = "true"
    const groupId = randomId()
    group.dataset.groupId = groupId
    const idInput = group.querySelector(ID_INPUT)
    if (idInput) {
      idInput.value = groupId
    }
    const positionInput = group.querySelector(POSITION_INPUT)
    if (positionInput) {
      positionInput.value = this.listTarget.querySelectorAll(GROUP).length
    }
    return group
  }

  appendOptionTo(group) {
    const uid = `new-${this.nextUid}`
    this.nextUid += 1
    const option = cloneTemplate(this.optionTemplateTarget, uid)
    if (!option) {
      return
    }
    option.dataset.new = "true"
    this.stampGroupId(option, group.dataset.groupId)
    group.querySelector(GROUP_OPTIONS_LIST)?.appendChild(option)
  }

  stampGroupId(option, groupId) {
    const input = option.querySelector(GROUP_ID_INPUT)
    if (input) {
      input.value = groupId
    }
  }

  unstampGroupId(option) {
    const input = option.querySelector(GROUP_ID_INPUT)
    if (input) {
      input.value = ""
    }
  }

  // dataset.new = unsaved → hard remove. Persisted → soft-delete (deleted=true + hidden).
  destroyOrRemove(element) {
    if (element.dataset.new === "true") {
      element.remove()
      return
    }
    const deletedInput = element.querySelector(DELETED_INPUT)
    if (deletedInput) {
      deletedInput.value = "true"
    }
    element.classList.add("hidden")
  }

  enableSortable() {
    sortable(this.listTarget, { forcePlaceholderSize: true, items: GROUP, handle: GROUP_DRAG_HANDLE })
  }

  resyncPositions() {
    this.listTarget.querySelectorAll(`${GROUP}:not(.hidden)`).forEach((group, idx) => {
      const input = group.querySelector(POSITION_INPUT)
      if (input) {
        input.value = idx
      }
    })
    this.runAutoLabel()
  }

  runAutoLabel() {
    Array.from(this.listTarget.querySelectorAll(GROUP)).
      filter((group) => !group.classList.contains("hidden")).
      forEach((group, idx) => {
        const label = group.querySelector(GROUP_POSITION_LABEL)
        if (label) {
          label.textContent = ` #${idx + 1}`
        }
      })
  }

  // Flat list lives outside our element scope; walk up to the toggle card.
  // Anchor injected by add_flat_list_hook.deface.
  findFlatList() {
    const card = this.element.closest("[data-controller~='grouped-question-toggle']")
    return card?.querySelector(FLAT_LIST) || null
  }
}
