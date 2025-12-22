/**
 * Custom CSV Census column builder for Decidim Elections.
 * Handles dynamic column configuration and CSV file upload.
 */

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
 * @param {HTMLElement} options.columnsList - Container for column rows
 * @param {HTMLElement} options.hiddenFields - Container for hidden inputs
 * @param {Object} options.config - Configuration object with labels and types
 * @param {string} options.name - Existing column name
 * @param {string} options.type - Existing column type
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
      <select class="column-type w-full">${typeOptions}</select>
    </div>
    <div class="flex items-center pb-1">
      <button type="button" class="delete-column-btn p-2 text-gray-2 hover:text-alert rounded" title="Delete">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="18" height="18" fill="currentColor">
          <path d="M17 6H22V8H20V21C20 21.5523 19.5523 22 19 22H5C4.44772 22 4 21.5523 4 21V8H2V6H7V3C7 2.44772 7.44772 2 8 2H16C16.5523 2 17 2.44772 17 3V6ZM18 8H6V20H18V8ZM9 11H11V17H9V11ZM13 11H15V17H13V11ZM9 4V6H15V4H9Z"></path>
        </svg>
      </button>
    </div>
  `;

  const updateHidden = () => updateHiddenFields(columnsList, hiddenFields, config.formPrefix);

  row.querySelector(".column-name").addEventListener("input", updateHidden);
  row.querySelector(".column-type").addEventListener("change", updateHidden);
  row.querySelector(".delete-column-btn").addEventListener("click", () => {
    row.remove();
    updateHidden();
  });

  columnsList.appendChild(row);
  updateHidden();
};

/**
 * Initializes the column builder UI.
 * @param {Object} options - Builder options
 * @param {HTMLElement} options.container - Main container element
 * @param {Object} options.config - Configuration object
 * @param {Array} options.columns - Existing columns array
 * @param {string} options.suffix - Element ID suffix
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
