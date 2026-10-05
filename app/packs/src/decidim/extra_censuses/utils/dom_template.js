// NEW_RECORD is the form array key used in the templates. The other two are
// the `to_param` placeholders of the blank ResponseOptionForm and
// ResponseOptionGroupForm, which end up in the language tabs ids. They must
// be uniquified too, otherwise every cloned field shares the same tab ids.
const PLACEHOLDERS = [
  "NEW_RECORD",
  "questionnaire-question-response-option-id",
  "questionnaire-question-response-option-group-id"
]

/**
 * Walks the DOM (not innerHTML.replaceAll) so user-typed strings containing
 * a placeholder can never be hit.
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
      let attrValue = attr.value
      for (const placeholder of PLACEHOLDERS) {
        if (attrValue.includes(placeholder)) {
          attrValue = attrValue.split(placeholder).join(value)
        }
      }
      if (attrValue !== attr.value) {
        el.setAttribute(attr.name, attrValue)
      }
    }
    for (const child of el.children) {
      stack.push(child)
    }
  }
}

/**
 * Clones an HTMLTemplateElement and substitutes the known placeholders
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
