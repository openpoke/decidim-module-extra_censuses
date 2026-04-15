// Mirrors decidim-admin/dynamic_fields.component.js#_getUID.
let elementCounter = 0

export default function randomId() {
  elementCounter += 1
  return (new Date().getTime()) + elementCounter
}
