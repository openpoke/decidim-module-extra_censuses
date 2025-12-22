/**
 * Custom CSV Census column builder for Decidim Elections.
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

const bindRowEvents = (row, onUpdate) => {
  row.querySelector(".column-name").addEventListener("input", onUpdate);
  row.querySelector(".column-type").addEventListener("change", onUpdate);
  row.querySelector(".delete-column-btn").addEventListener("click", () => {
    row.remove();
    onUpdate();
  });
};

const cloneColumnRow = () => {
  const template = document.getElementById("column-row-template");
  return template.content.firstElementChild.cloneNode(true);
};

const initColumnBuilder = ({ container, formPrefix, suffix = "" }) => {
  const columnsList = container.querySelector(`#columns-list${suffix}`);
  const hiddenFields = container.querySelector(`#hidden-fields${suffix}`);
  const addColumnBtn = container.querySelector(`#add-column-btn${suffix}`);
  const saveBtn = container.querySelector(`#save-columns${suffix}-btn`);
  const parentForm = document.getElementById("census-election-form");

  const updateHidden = () => updateHiddenFields(columnsList, hiddenFields, formPrefix);

  columnsList.querySelectorAll("[data-column-row]").forEach((row) => {
    bindRowEvents(row, updateHidden);
  });

  updateHidden();

  addColumnBtn.addEventListener("click", () => {
    const row = cloneColumnRow();
    bindRowEvents(row, updateHidden);
    columnsList.appendChild(row);
    updateHidden();
  });

  if (saveBtn && parentForm) {
    saveBtn.addEventListener("click", (event) => {
      event.preventDefault();
      clearUploadedFiles(parentForm);
      hiddenFields.querySelectorAll("input").forEach((input) => {
        parentForm.appendChild(input.cloneNode(true));
      });

      fetch(parentForm.action, {
        method: "PATCH",
        body: new FormData(parentForm),
        headers: { "X-Requested-With": "XMLHttpRequest" },
        credentials: "same-origin"
      }).then(() => window.location.reload());
    });
  }
};

const initEditMode = (container, formPrefix) => {
  const toggleBtn = container.querySelector("#toggle-edit-btn");
  const editorSection = container.querySelector("#column-editor-section");
  const uploadSection = container.querySelector("#upload-section");
  let initialized = false;

  toggleBtn.addEventListener("click", () => {
    const isHidden = editorSection.classList.contains("hidden");
    editorSection.classList.toggle("hidden", !isHidden);
    uploadSection.classList.toggle("hidden", isHidden);

    if (isHidden && !initialized) {
      initColumnBuilder({ container, formPrefix, suffix: "-edit" });
      initialized = true;
    }
  });
};

const initCustomCsvCensus = () => {
  const container = document.querySelector("[data-custom-csv-census]");
  if (!container || container.dataset.initialized === "true") {
    return;
  }

  container.dataset.initialized = "true";
  const { formPrefix, configured } = container.dataset;

  if (configured === "true") {
    initEditMode(container, formPrefix);
  } else {
    initColumnBuilder({ container, formPrefix });
  }
};

document.addEventListener("DOMContentLoaded", initCustomCsvCensus);
document.addEventListener("turbo:load", initCustomCsvCensus);
