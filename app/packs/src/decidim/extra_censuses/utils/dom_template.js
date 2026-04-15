const PLACEHOLDER = "NEW_RECORD"

export default function cloneTemplate(template, uid) {
  if (!template) return null
  const root = template.content.cloneNode(true).firstElementChild
  if (!root) return null
  substitutePlaceholder(root, uid)
  return root
}

// Walks the DOM (not innerHTML.replaceAll) so user-typed strings containing
// NEW_RECORD can never be hit.
function substitutePlaceholder(root, value) {
  const stack = [root]
  while (stack.length > 0) {
    const el = stack.pop()
    for (const attr of Array.from(el.attributes)) {
      if (attr.value.includes(PLACEHOLDER)) {
        el.setAttribute(attr.name, attr.value.split(PLACEHOLDER).join(value))
      }
    }
    for (const child of el.children) stack.push(child)
  }
}
