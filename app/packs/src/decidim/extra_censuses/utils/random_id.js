let elementCounter = 0

/**
 * Mirrors decidim-admin/dynamic_fields.component.js#_getUID.
 *
 * @returns {number} a numeric id unique within the current page session
 */
const randomId = function() {
  elementCounter += 1
  return (new Date().getTime()) + elementCounter
}

export default randomId
