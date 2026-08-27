import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["label", "trigger", "form", "input"]

  open() {
    this.originalValue = this.inputTarget.value
    this.labelTarget.classList.add("d-none")
    this.triggerTarget.classList.add("d-none")
    this.formTarget.classList.remove("d-none")
    this.inputTarget.focus()
    this.inputTarget.select()
  }

  submit() {
    if (this.canceling || this.submitting) return

    if (this.inputTarget.value === this.originalValue) {
      this.cancel()
      return
    }

    this.submitting = true
    this.formTarget.requestSubmit()
  }

  cancel() {
    this.canceling = true
    this.inputTarget.value = this.originalValue
    this.formTarget.classList.add("d-none")
    this.labelTarget.classList.remove("d-none")
    this.triggerTarget.classList.remove("d-none")
    this.triggerTarget.focus()
    queueMicrotask(() => { this.canceling = false })
  }

  keydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.submit()
    }

    if (event.key === "Escape") {
      event.preventDefault()
      this.cancel()
    }
  }
}
