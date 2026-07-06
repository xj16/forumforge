import { Controller } from "@hotwired/stimulus"

// Toggles an inline reply form open/closed and focuses the textarea.
// Used on each post so users can reply to a specific comment without leaving
// the page. Works together with Turbo Streams that live-append new replies.
export default class extends Controller {
  static targets = ["form", "trigger"]

  connect() {
    this.close()
  }

  toggle(event) {
    if (event) event.preventDefault()
    if (this.hasFormTarget) {
      this.formTarget.hidden ? this.open() : this.close()
    }
  }

  open() {
    if (!this.hasFormTarget) return
    this.formTarget.hidden = false
    const textarea = this.formTarget.querySelector("textarea")
    if (textarea) textarea.focus()
  }

  close() {
    if (this.hasFormTarget) this.formTarget.hidden = true
  }
}
