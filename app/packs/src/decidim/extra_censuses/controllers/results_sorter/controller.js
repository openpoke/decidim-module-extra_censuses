import { Controller } from "@hotwired/stimulus"

const SORT_ASC = "ascending"
const SORT_DESC = "descending"
const SORT_NONE = "none"
const CARET_ASC = " ▲"
const CARET_DESC = " ▼"
const CARET_CLASS = "results-sorter-caret"

export default class extends Controller {
	connect() {
		const nestedTables = Array.from(this.element.querySelectorAll("table"))
		this.tables = this.element.matches("table") ? [this.element, ...nestedTables] : nestedTables
		this.tableState = new WeakMap()
		this.boundHeaderClick = this.onHeaderClick.bind(this)
		this.boundHeaderKeydown = this.onHeaderKeydown.bind(this)

		this.tables.forEach((table) => this.initializeTable(table))
	}

	disconnect() {
		this.tables?.forEach((table) => {
			table.querySelectorAll("th[data-sortable='true']").forEach((header) => {
				header.removeEventListener("click", this.boundHeaderClick)
				header.removeEventListener("keydown", this.boundHeaderKeydown)
			})
		})
	}

	initializeTable(table) {
		const headers = this.sortableHeaders(table)
		if (!headers.length) {
			return
		}

		headers.forEach((header) => {
			header.dataset.sortable = "true"
			header.setAttribute("aria-sort", SORT_NONE)
			header.setAttribute("role", "button")
			header.setAttribute("tabindex", "0")
			this.updateHeaderCaret(header, SORT_NONE)

			if (!header.style.cursor) {
				header.style.cursor = "pointer"
			}

			header.addEventListener("click", this.boundHeaderClick)
			header.addEventListener("keydown", this.boundHeaderKeydown)
		})
	}

	onHeaderClick(event) {
		const header = event.currentTarget
		const table = header.closest("table")
		if (!table) {
			return
		}

		const columnIndex = header.cellIndex
		if (columnIndex < 0) {
			return
		}

		const nextDirection = this.nextDirection(table, columnIndex)
		this.sortTable(table, columnIndex, nextDirection)
	}

	onHeaderKeydown(event) {
		if (event.key !== "Enter" && event.key !== " ") {
			return
		}

		event.preventDefault()
		event.currentTarget.click()
	}

	nextDirection(table, columnIndex) {
		const state = this.tableState.get(table)
		if (!state || state.columnIndex !== columnIndex) {
			return SORT_ASC
		}

		return state.direction === SORT_ASC ? SORT_DESC : SORT_ASC
	}

	sortTable(table, columnIndex, direction) {
		const tbody = table.tBodies[0]
		if (!tbody) {
			return
		}

		const rows = Array.from(tbody.rows)
		if (rows.length < 2) {
			return
		}

		const tableColumnCount = this.tableColumnCount(table)
		const chunks = this.buildSortableChunks(rows, tableColumnCount)
		const sortableRows = chunks
			.filter((chunk) => chunk.type === "data")
			.flatMap((chunk) => chunk.rows)
			.filter((row) => row.dataset.sortFixed !== "true")
		const valueType = this.detectColumnType(sortableRows, columnIndex)
		const fragment = document.createDocumentFragment()

		chunks.forEach((chunk) => {
			if (chunk.type === "title") {
				fragment.appendChild(chunk.row)
				return
			}

			const fixedRows = chunk.rows.filter((row) => row.dataset.sortFixed === "true")
			const movableRows = chunk.rows.filter((row) => row.dataset.sortFixed !== "true")

			const normalizedRows = movableRows.map((row, index) => {
				const rawValue = this.cellRawValue(row, columnIndex)

				return {
					row,
					index,
					parsedValue: this.parseValueByType(rawValue, valueType)
				}
			})

			normalizedRows.sort((a, b) => {
				const comparison = this.compareValues(a.parsedValue, b.parsedValue, direction)
				if (comparison !== 0) {
					return comparison
				}

				return a.index - b.index
			})

			normalizedRows.forEach(({ row }) => fragment.appendChild(row))
			fixedRows.forEach((row) => fragment.appendChild(row))
		})

		tbody.appendChild(fragment)

		this.updateHeaderState(table, columnIndex, direction)
		this.tableState.set(table, { columnIndex, direction })
	}

	buildSortableChunks(rows, tableColumnCount) {
		const chunks = []
		let currentDataChunk = []

		rows.forEach((row) => {
			if (this.isSectionTitleRow(row, tableColumnCount)) {
				if (currentDataChunk.length) {
					chunks.push({ type: "data", rows: currentDataChunk })
					currentDataChunk = []
				}

				chunks.push({ type: "title", row })
				return
			}

			currentDataChunk.push(row)
		})

		if (currentDataChunk.length) {
			chunks.push({ type: "data", rows: currentDataChunk })
		}

		return chunks
	}

	isSectionTitleRow(row, tableColumnCount) {
		if (row.dataset.sortSectionTitle === "true") {
			return true
		}

		if (row.cells.length !== 1) {
			return false
		}

		const cell = row.cells[0]
		const colSpan = Number(cell.colSpan || 1)
		return colSpan >= tableColumnCount
	}

	tableColumnCount(table) {
		const headerRows = Array.from(table.tHead?.rows || [])
		const referenceRow = headerRows[headerRows.length - 1] || table.tBodies[0]?.rows[0]
		if (!referenceRow) {
			return 1
		}

		return Array.from(referenceRow.cells).reduce((total, cell) => total + Number(cell.colSpan || 1), 0)
	}

	updateHeaderState(table, activeColumnIndex, direction) {
		this.sortableHeaders(table).forEach((header) => {
			const isActive = header.cellIndex === activeColumnIndex
			header.setAttribute("aria-sort", isActive ? direction : SORT_NONE)
			header.dataset.sortDirection = isActive ? direction : ""
			this.updateHeaderCaret(header, isActive ? direction : SORT_NONE)
		})
	}

	updateHeaderCaret(header, direction) {
		const caret = this.ensureHeaderCaret(header)

		if (direction === SORT_ASC) {
			caret.textContent = CARET_ASC
			return
		}

		if (direction === SORT_DESC) {
			caret.textContent = CARET_DESC
			return
		}

		caret.textContent = ""
	}

	ensureHeaderCaret(header) {
		let caret = header.querySelector("[data-sort-caret='true']")
		if (caret) {
			return caret
		}

		caret = document.createElement("span")
		caret.dataset.sortCaret = "true"
		caret.className = CARET_CLASS
		caret.setAttribute("aria-hidden", "true")
		header.appendChild(caret)

		return caret
	}

	sortableHeaders(table) {
		const thead = table.tHead
		if (!thead || !thead.rows.length) {
			return []
		}

		const headerRow = thead.rows[thead.rows.length - 1]
		return Array.from(headerRow.cells).filter((header) => {
			const sortable = header.dataset.sortable
			if (sortable === "false") {
				return false
			}

			return Number(header.colSpan || 1) === 1
		})
	}

	detectColumnType(rows, columnIndex) {
		const rawValues = rows
			.map((row) => this.cellRawValue(row, columnIndex))
			.map((value) => value.trim())
			.filter((value) => value.length > 0)

		if (!rawValues.length) {
			return "text"
		}

		const allNumbers = rawValues.every((value) => this.parseNumber(value) !== null)
		if (allNumbers) {
			return "number"
		}

		const allDates = rawValues.every((value) => this.parseDate(value) !== null)
		if (allDates) {
			return "date"
		}

		return "text"
	}

	parseValueByType(value, type) {
		if (!value) {
			return null
		}

		if (type === "number") {
			return this.parseNumber(value)
		}

		if (type === "date") {
			return this.parseDate(value)
		}

		return value.toLocaleLowerCase()
	}

	compareValues(a, b, direction) {
		if (a === null && b === null) {
			return 0
		}

		if (a === null) {
			return 1
		}

		if (b === null) {
			return -1
		}

		if (typeof a === "string" && typeof b === "string") {
			const result = a.localeCompare(b, undefined, { numeric: true, sensitivity: "base" })
			return direction === SORT_ASC ? result : -result
		}

		if (a === b) {
			return 0
		}

		const result = a > b ? 1 : -1
		return direction === SORT_ASC ? result : -result
	}

	parseNumber(value) {
		const sanitized = value
			.trim()
			.replace(/\s+/g, "")
			.replace(/%$/, "")
			.replace(/[^0-9,.-]/g, "")

		if (!sanitized || sanitized === "-" || sanitized === "." || sanitized === ",") {
			return null
		}

		let normalized = sanitized
		const hasComma = normalized.includes(",")
		const hasDot = normalized.includes(".")

		if (hasComma && hasDot) {
			const lastComma = normalized.lastIndexOf(",")
			const lastDot = normalized.lastIndexOf(".")
			if (lastComma > lastDot) {
				normalized = normalized.replace(/\./g, "").replace(",", ".")
			} else {
				normalized = normalized.replace(/,/g, "")
			}
		} else if (hasComma) {
			const decimalLikeComma = /,\d{1,4}$/.test(normalized)
			normalized = decimalLikeComma ? normalized.replace(",", ".") : normalized.replace(/,/g, "")
		}

		const parsed = Number(normalized)
		return Number.isNaN(parsed) ? null : parsed
	}

	parseDate(value) {
		const timestamp = Date.parse(value)
		return Number.isNaN(timestamp) ? null : timestamp
	}

	cellRawValue(row, columnIndex) {
		const cell = row.cells[columnIndex]
		if (!cell) {
			return ""
		}

		const dataValue = cell.dataset.sortValue
		if (typeof dataValue === "string") {
			return dataValue
		}

		return cell.textContent?.trim() || ""
	}
}
