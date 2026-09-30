import { Controller } from "@hotwired/stimulus"

// Swaps the borda results panel for the winners panel and flips the button
// label. The button text comes from data-show-winners / data-show-results so
// the controller stays locale-agnostic.
export default class extends Controller {
  static get targets() {
    return ["results", "winners", "button"]
  }

  toggle() {
    if (!this.hasResultsTarget || !this.hasWinnersTarget) {
      return
    }

    const winnersHidden = this.winnersTarget.classList.contains("hidden")
    this.winnersTarget.classList.toggle("hidden", !winnersHidden)
    this.resultsTarget.classList.toggle("hidden", winnersHidden)

    if (this.hasButtonTarget) {
      this.buttonTarget.textContent = winnersHidden
        ? this.buttonTarget.dataset.showResults
        : this.buttonTarget.dataset.showWinners
    }
  }
}
