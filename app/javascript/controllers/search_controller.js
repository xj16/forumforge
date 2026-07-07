import { Controller } from "@hotwired/stimulus"

// Debounced live search. As the user types, we requestSubmit() the enclosing
// form after a short pause; the form's data-turbo-frame="search_results" makes
// Turbo swap only the results frame — no full navigation, no page reload.
//
// Progressive enhancement: with JS off, the form still submits normally on
// Enter / the Search button, so search works without this controller.
export default class extends Controller {
  static targets = ["form", "input"]
  static values = { delay: { type: Number, default: 250 } }

  connect() {
    this.timer = null
  }

  disconnect() {
    if (this.timer) clearTimeout(this.timer)
  }

  submit() {
    if (this.timer) clearTimeout(this.timer)
    this.timer = setTimeout(() => this.perform(), this.delayValue)
  }

  perform() {
    const form = this.hasFormTarget ? this.formTarget : this.element
    if (typeof form.requestSubmit === "function") {
      form.requestSubmit()
    } else {
      form.submit()
    }
  }
}
