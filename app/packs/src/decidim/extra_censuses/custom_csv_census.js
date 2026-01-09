/**
 * Custom CSV Census column builder for Decidim Elections.
 */

const createHiddenInput = (name, value) => {
  const input = document.createElement("input");
  input.type = "hidden";
  input.name = name;
  input.value = value;
  return input;
};

const updateHiddenFields = (columnsList, hiddenFields, formPrefix) => {
  hiddenFields.innerHTML = "";

  columnsList.querySelectorAll("[data-column-row]").forEach((row, index) => {
    const name = row.querySelector(".column-name").value.trim();
    const type = row.querySelector(".column-type").value;

    hiddenFields.appendChild(
      createHiddenInput(`${formPrefix}[columns][${index}][name]`, name)
    );
    hiddenFields.appendChild(
      createHiddenInput(`${formPrefix}[columns][${index}][column_type]`, type)
    );
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

const updateStickyButtonText = (text) => {
  const stickyButton = document.querySelector(".item__edit-sticky button[form='census-election-form']");
  if (stickyButton) {
    stickyButton.textContent = text;
  }
};

const initColumnBuilder = ({ container, formPrefix, suffix = "", buttonText = null }) => {
  const columnsList = container.querySelector(`#columns-list${suffix}`);
  const hiddenFields = container.querySelector(`#hidden-fields${suffix}`);
  const addColumnBtn = container.querySelector(`#add-column-btn${suffix}`);
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

  if (parentForm && suffix === "-edit") {
    parentForm.addEventListener("submit", () => {
      clearUploadedFiles(parentForm);
    });
  }

  if (buttonText) {
    updateStickyButtonText(buttonText);
  }
};

const initEditMode = (container, formPrefix, buttonText, originalButtonText) => {
  const toggleBtn = container.querySelector("#toggle-edit-btn");
  const editorSection = container.querySelector("#column-editor-section");
  const uploadSection = container.querySelector("#upload-section");
  const parentForm = document.getElementById("census-election-form");
  let initialized = false;

  toggleBtn.addEventListener("click", () => {
    const isHidden = editorSection.classList.contains("hidden");
    editorSection.classList.toggle("hidden", !isHidden);
    uploadSection.classList.toggle("hidden", isHidden);

    if (isHidden) {
      if (parentForm) {
        clearUploadedFiles(parentForm);
      }
      updateStickyButtonText(buttonText);

      if (!initialized) {
        initColumnBuilder({ container, formPrefix, suffix: "-edit" });
        initialized = true;
      }
    } else {
      updateStickyButtonText(originalButtonText);
    }
  });
};

const initCustomCsvCensus = () => {
  const container = document.querySelector("[data-custom-csv-census]");
  if (!container || container.dataset.initialized === "true") {
    return;
  }

  container.dataset.initialized = "true";
  const { formPrefix, configured, buttonText } = container.dataset;
  const stickyButton = document.querySelector(".item__edit-sticky button[form='census-election-form']");
  const originalButtonText = stickyButton?.textContent || "";

  if (configured === "true") {
    initEditMode(container, formPrefix, buttonText, originalButtonText);
  } else {
    initColumnBuilder({ container, formPrefix, buttonText });
  }
};

document.addEventListener("DOMContentLoaded", initCustomCsvCensus);
document.addEventListener("turbo:load", initCustomCsvCensus);
