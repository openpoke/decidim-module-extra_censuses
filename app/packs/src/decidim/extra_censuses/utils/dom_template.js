const PLACEHOLDER = "NEW_RECORD"

/**
 * Walks the DOM (not innerHTML.replaceAll) so user-typed strings containing
 * NEW_RECORD can never be hit.
 *
 * @param {HTMLElement} root the subtree root to walk
 * @param {string} value the substitution value
 * @returns {void}
 */
const substitutePlaceholder = function(root, value) {
  const stack = [root]
  while (stack.length > 0) {
    const el = stack.pop()
    for (const attr of Array.from(el.attributes)) {
      if (attr.value.includes(PLACEHOLDER)) {
        el.setAttribute(attr.name, attr.value.split(PLACEHOLDER).join(value))
      }
    }
    for (const child of el.children) {
      stack.push(child)
    }
  }
}

/**
 * Clones an HTMLTemplateElement and substitutes the NEW_RECORD placeholder
 * with `uid` across every attribute of the cloned subtree.
 *
 * @param {HTMLTemplateElement} template the source template
 * @param {string} uid the substitution value for the placeholder
 * @returns {HTMLElement|null} the cloned root element, or null if missing
 */
const cloneTemplate = function(template, uid) {
  if (!template) {
    return null
  }
  const root = template.content.cloneNode(true).firstElementChild
  if (!root) {
    return null
  }
  substitutePlaceholder(root, uid)
  return root
}

export default cloneTemplate
