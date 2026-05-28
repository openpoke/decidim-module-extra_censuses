/* eslint-disable max-params */
// Mirrors decidim-elections live_results_update.js, but updates only the BORDA
// Score column. The upstream poller has no DOM event, hook or pub/sub to attach
// to, so a dedicated poller is the only non-invasive option; its cadence and
// stop-condition are kept identical to upstream (4s, stop when !data.ongoing).
document.addEventListener("DOMContentLoaded", () => {
  const watchingDiv = document.querySelector("[data-results-live-update]");
  if (!watchingDiv) {
    return;
  }

  const url = watchingDiv.dataset.resultsLiveUpdate;
  const optionBordaScoreTexts = () => document.querySelectorAll("[data-option-borda-score-text]");

  const animateText = (element, value) => {
    if (element.textContent === value) {
      return;
    }
    element.textContent = value;
    element.classList.add("live_results-number_changing");
    setTimeout(() => {
      element.classList.remove("live_results-number_changing");
    }, 1000);
  };

  const digOptionValue = (questionId, optionId, data, key) => {
    const questions = data.questions || [];
    const question = questions.find((item) => item.id === parseInt(questionId, 10));
    if (!question) {
      return null;
    }
    const responseOptions = question.response_options || [];
    if (!Array.isArray(responseOptions)) {
      return null;
    }
    const option = responseOptions.find((item) => item.id === parseInt(optionId, 10));
    if (!option || !(key in option)) {
      return null;
    }
    return option[key];
  };

  const fetchResults = async () => {
    try {
      const response = await fetch(url, {
        method: "GET",
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "X-Requested-With": "XMLHttpRequest"
        }
      });
      if (!response.ok) {
        throw new Error("Network response was not ok");
      }
      const data = await response.json();
      optionBordaScoreTexts().forEach((el) => {
        const [questionId, optionId] = el.dataset.optionBordaScoreText.split(",");
        const val = digOptionValue(questionId, optionId, data, "borda_score_text");
        if (val !== null) {
          animateText(el, val);
        }
      });
      // repeat for ongoing elections only
      if (data.ongoing) {
        setTimeout(fetchResults, 4000);
      }
    } catch (error) {
      console.error("Error fetching borda scores:", error);
    }
  };

  fetchResults();
});
