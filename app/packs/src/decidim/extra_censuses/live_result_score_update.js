/* eslint-disable max-params */
// Mirrors decidim-elections live_results_update.js, but updates only the
// Score column. The upstream poller has no DOM event, hook or pub/sub to attach
// to, so a dedicated poller is the only non-invasive option; its cadence and
// stop-condition are kept identical to upstream (4s, stop when !data.ongoing).
document.addEventListener("DOMContentLoaded", () => {
  const watchingDiv = document.querySelector("[data-results-live-update]");
  if (!watchingDiv || !document.querySelector("[data-option-result-score-text]")) {
    return;
  }

  const url = watchingDiv.dataset.resultsLiveUpdate;
  const optionResultScoreTexts = () => document.querySelectorAll("[data-option-result-score-text]");
  const optionResultScorePercentTexts = () => document.querySelectorAll("[data-option-result-score-percent-text]");
  const optionResultScoreWidths = () => document.querySelectorAll("[data-option-result-score-width]");
  const questionTotalScoreTexts = () => document.querySelectorAll("[data-question-total-score-text]");

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

  const digQuestionValue = (questionId, data, key) => {
    const questions = data.questions || [];
    const question = questions.find((item) => item.id === parseInt(questionId, 10));
    if (!question || !(key in question)) {
      return null;
    }
    return question[key];
  };

  const totalResultScore = (questionId, data) => {
    const questions = data.questions || [];
    const question = questions.find((item) => item.id === parseInt(questionId, 10));
    if (!question || !Array.isArray(question.response_options)) {
      return 0;
    }
    return question.response_options.reduce((sum, option) => {
      const score = typeof option.result_score === "number"
        ? option.result_score
        : 0;
      return sum + score;
    }, 0);
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
      optionResultScoreTexts().forEach((el) => {
        const [questionId, optionId] = el.dataset.optionResultScoreText.split(",");
        const val = digOptionValue(questionId, optionId, data, "result_score_text");
        if (val !== null) {
          animateText(el, val);
        }
      });
      optionResultScorePercentTexts().forEach((el) => {
        const [questionId, optionId] = el.dataset.optionResultScorePercentText.split(",");
        const val = digOptionValue(questionId, optionId, data, "result_score_percent_text");
        if (val !== null) {
          animateText(el, val);
        }
      });
      optionResultScoreWidths().forEach((el) => {
        const [questionId, optionId] = el.dataset.optionResultScoreWidth.split(",");
        const score = digOptionValue(questionId, optionId, data, "result_score");
        const total = totalResultScore(questionId, data);
        if (score !== null && total > 0) {
          el.style.width = `${Math.round((score / total) * 1000) / 10}%`;
        }
      });
      questionTotalScoreTexts().forEach((el) => {
        const val = digQuestionValue(el.dataset.questionTotalScoreText, data, "result_score_total_text");
        if (val !== null) {
          animateText(el, val);
        }
      });
      if (data.ongoing) {
        setTimeout(fetchResults, 4000);
      }
    } catch (error) {
      console.error("Error fetching result scores:", error);
    }
  };

  fetchResults();
});
