/**
 * Custom CSV Census column builder for Decidim Elections.
 */
import icon from "src/decidim/refactor/moved/icon";

/**
 * Creates hidden input fields for form submission.
 * @param {HTMLElement} columnsList - Container with column rows
 * @param {HTMLElement} hiddenFields - Container for hidden inputs
 * @param {string} formPrefix - Form field name prefix
 * @returns {void}
 */
const updateHiddenFields = (columnsList, hiddenFields, formPrefix) => {
  hiddenFields.innerHTML = "";

  columnsList.querySelectorAll("[data-column-row]").forEach((row, index) => {
    const name = row.querySelector(".column-name").value;
    const type = row.querySelector(".column-type").value;

    hiddenFields.insertAdjacentHTML("beforeend", `
      <input type="hidden" name="${formPrefix}[columns][${index}][name]" value="${name}">
      <input type="hidden" name="${formPrefix}[columns][${index}][column_type]" value="${type}">
    `);
  });
};

const clearUploadedFiles = (form) => {
  form.querySelectorAll("input[type='file']").forEach((input) => {
    input.value = "";
  });
  form.querySelectorAll("[data-active-uploads]").forEach((container) => {
    container.innerHTML = "";
  });
  form.querySelectorAll("input[type='hidden'][name*='[file]']").forEach((input) => {
    input.remove();
  });
};

const submitColumns = (parentForm, hiddenFields) => {
  clearUploadedFiles(parentForm);

  hiddenFields.querySelectorAll("input").forEach((input) => {
    parentForm.appendChild(input.cloneNode(true));
  });

  fetch(parentForm.action, {
    method: "PATCH",
    body: new FormData(parentForm),
    headers: { Accept: "text/html", "X-Requested-With": "XMLHttpRequest" },
    credentials: "same-origin"
  }).finally(() => window.location.reload());
};

/**
 * Adds a column row to the builder.
 * @param {Object} options - Row options
 * @returns {void}
 */
const addColumnRow = ({ columnsList, hiddenFields, config, name = "", type = "free_text" }) => {
  const row = document.createElement("div");
  row.className = "flex gap-4 p-4 mb-3 bg-background border border-gray-3 rounded items-end";
  row.dataset.columnRow = "true";

  const typeOptions = Object.entries(config.columnTypes).
    map(([value, label]) => {
      const selected = value === type
        ? " selected"
        : "";
      return `<option value="${value}"${selected}>${label}</option>`;
    }).
    join("");

  row.innerHTML = `
    <div class="flex-1">
      <label class="block font-medium mb-2 text-gray-2">${config.labels.columnName}</label>
      <input type="text" class="column-name w-full" value="${name}">
    </div>
    <div class="flex-1">
      <label class="block font-medium mb-2 text-gray-2">${config.labels.columnType}</label>
      <select class="column-type w-full" title="${config.labels.columnType}">${typeOptions}</select>
    </div>
    <div class="flex items-center pb-1">
      <button type="button" class="delete-column-btn p-2 text-gray-2 hover:text-alert rounded" title="Delete">
        ${icon("delete-bin-line", { class: "w-4 h-4 fill-current" })}
      </button>
    </div>
  `;

  const nameInput = row.querySelector(".column-name");
  const typeSelect = row.querySelector(".column-type");
  const deleteBtn = row.querySelector(".delete-column-btn");
  const updateHidden = () => updateHiddenFields(columnsList, hiddenFields, config.formPrefix);

  nameInput.addEventListener("input", updateHidden);
  typeSelect.addEventListener("change", updateHidden);
  deleteBtn.addEventListener("click", () => {
    row.remove();
    updateHidden();
  });

  columnsList.appendChild(row);
  updateHidden();
};

/**
 * Initializes the column builder UI.
 * @param {Object} options - Builder options
 * @returns {void}
 */
const initColumnBuilder = ({ container, config, columns, suffix = "" }) => {
  const columnsList = container.querySelector(`#columns-list${suffix}`);
  const hiddenFields = container.querySelector(`#hidden-fields${suffix}`);
  const addColumnBtn = container.querySelector(`#add-column-btn${suffix}`);
  const saveBtn = container.querySelector(`#save-columns${suffix}-btn`);
  const parentForm = document.getElementById("census-election-form");

  columnsList.innerHTML = "";

  const initialColumns = columns.length
    ? columns
    : [{ name: "", column_type: "free_text" }]; // eslint-disable-line camelcase

  initialColumns.forEach((col) => {
    addColumnRow({
      columnsList,
      hiddenFields,
      config,
      name: col.name,
      type: col.column_type // eslint-disable-line camelcase
    });
  });

  addColumnBtn.addEventListener("click", () => {
    addColumnRow({ columnsList, hiddenFields, config });
  });

  if (saveBtn && parentForm) {
    saveBtn.addEventListener("click", (event) => {
      event.preventDefault();
      submitColumns(parentForm, hiddenFields);
    });
  }
};

/**
 * Initializes edit mode for existing configuration.
 * @param {HTMLElement} container - Main container element
 * @param {Object} config - Configuration object
 * @param {Array} savedColumns - Saved columns array
 * @returns {void}
 */
const initEditMode = (container, config, savedColumns) => {
  const toggleBtn = container.querySelector("#toggle-edit-btn");
  const editorSection = container.querySelector("#column-editor-section");
  const uploadSection = container.querySelector("#upload-section");

  toggleBtn.addEventListener("click", () => {
    const isHidden = editorSection.classList.contains("hidden");
    editorSection.classList.toggle("hidden", !isHidden);
    uploadSection.classList.toggle("hidden", isHidden);

    if (isHidden) {
      initColumnBuilder({ container, config, columns: savedColumns, suffix: "-edit" });
    }
  });
};

/**
 * Main initialization function for Custom CSV Census.
 * @returns {void}
 */
const initCustomCsvCensus = () => {
  const container = document.querySelector("[data-custom-csv-census]");

  if (!container || container.dataset.initialized === "true") {
    return;
  }

  container.dataset.initialized = "true";

  const config = JSON.parse(container.dataset.config || "{}");
  const savedColumns = JSON.parse(container.dataset.savedColumns || "[]");
  const isConfigured = container.dataset.configured === "true";

  if (isConfigured) {
    initEditMode(container, config, savedColumns);
  } else {
    initColumnBuilder({ container, config, columns: [] });
  }
};

document.addEventListener("DOMContentLoaded", initCustomCsvCensus);
document.addEventListener("turbo:load", initCustomCsvCensus);
