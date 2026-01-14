/**
 * Survey Import for Decidim Elections.
 * Handles dynamic loading of surveys and questions.
 */

const updateSelectOptions = (select, options, placeholderText) => {
  select.innerHTML = "";

  const placeholder = document.createElement("option");
  placeholder.value = "";
  placeholder.textContent = placeholderText;
  select.appendChild(placeholder);

  options.forEach((option) => {
    const opt = document.createElement("option");
    opt.value = option.id;
    opt.textContent = option.title || option.body;
    select.appendChild(opt);
  });
};

const fetchSurveys = async (url, componentId) => {
  try {
    const response = await fetch(`${url}?survey_component_id=${componentId}`, {
      headers: {
        Accept: "application/json",
        "X-Requested-With": "XMLHttpRequest"
      }
    });

    if (!response.ok) {
      console.error("Failed to fetch surveys:", response.status);
      return [];
    }

    return response.json();
  } catch (error) {
    console.error("Error fetching surveys:", error);
    return [];
  }
};

const fetchQuestions = async (url, surveyId) => {
  try {
    const response = await fetch(`${url}?survey_id=${surveyId}`, {
      headers: {
        Accept: "application/json",
        "X-Requested-With": "XMLHttpRequest"
      }
    });

    if (!response.ok) {
      console.error("Failed to fetch questions:", response.status);
      return [];
    }

    return response.json();
  } catch (error) {
    console.error("Error fetching questions:", error);
    return [];
  }
};

const initSurveyImport = () => {
  const form = document.getElementById("survey_import_config_form");
  if (!form || form.dataset.initialized === "true") {
    return;
  }

  form.dataset.initialized = "true";

  const componentSelect = form.querySelector("[data-survey-import-target='componentSelect']");
  const surveySelect = form.querySelector("[data-survey-import-target='surveySelect']");
  const questionSelects = form.querySelectorAll("[data-survey-import-target='questionSelect']");

  if (!componentSelect || !surveySelect) {
    return;
  }

  const surveysUrl = componentSelect.dataset.surveysUrl;
  const questionsUrl = surveySelect.dataset.questionsUrl;

  componentSelect.addEventListener("change", async () => {
    const componentId = componentSelect.value;

    surveySelect.innerHTML = "<option value=\"\">Loading...</option>";
    questionSelects.forEach((select) => {
      select.innerHTML = "<option value=\"\">Select a question</option>";
    });

    if (!componentId) {
      updateSelectOptions(surveySelect, [], "Select a survey");
      return;
    }

    const surveys = await fetchSurveys(surveysUrl, componentId);
    updateSelectOptions(surveySelect, surveys, "Select a survey");
  });

  surveySelect.addEventListener("change", async () => {
    const surveyId = surveySelect.value;

    questionSelects.forEach((select) => {
      select.innerHTML = "<option value=\"\">Loading...</option>";
    });

    if (!surveyId) {
      questionSelects.forEach((select) => {
        select.innerHTML = "<option value=\"\">Select a question</option>";
      });
      return;
    }

    const questions = await fetchQuestions(questionsUrl, surveyId);
    questionSelects.forEach((select) => {
      updateSelectOptions(select, questions, "Select a question");
    });
  });
};

const initResponseSelection = () => {
  const selectAllCheckbox = document.getElementById("select_all_responses");
  if (!selectAllCheckbox) {
    return;
  }

  selectAllCheckbox.addEventListener("change", () => {
    const checkboxes = document.querySelectorAll(".response-checkbox");
    checkboxes.forEach((checkbox) => {
      checkbox.checked = selectAllCheckbox.checked;
    });
  });
};

const initAll = () => {
  initSurveyImport();
  initResponseSelection();
};

document.addEventListener("DOMContentLoaded", initAll);
document.addEventListener("turbo:load", initAll);
