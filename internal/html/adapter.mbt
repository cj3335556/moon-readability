///|
/// A parsed HTML document owned by the extraction pipeline.
pub struct Document {
  root : @html_parser.Node
}

///|
/// A DOM node exposed without leaking the parser's public types.
pub struct Node {
  inner : @html_parser.Node
}

///|
fn wrap(node : @html_parser.Node) -> Node {
  { inner: node }
}

///|
/// Parses an HTML string into an internal document.
pub fn parse(html : String) -> Document raise @html_parser.HtmlError {
  let parsed = @html_parser.parse(html)
  { root: parsed.root }
}

///|
/// Returns the document title, or an empty string when no title exists.
pub fn Document::title(self : Document) -> String {
  match @html_parser.query_one(self.root, "title") {
    Some(node) => node.text().trim().to_owned()
    None => ""
  }
}

///|
/// Returns the document body text, falling back to the whole document.
pub fn Document::body_text(self : Document) -> String {
  match @html_parser.query_one(self.root, "body") {
    Some(node) => node.text()
    None => self.root.text()
  }
}

///|
/// Returns the document body as a node.
pub fn Document::body(self : Document) -> Node? {
  match @html_parser.query_one(self.root, "body") {
    Some(node) => Some(wrap(node))
    None => None
  }
}

///|
/// Returns the document body as serialized HTML.
pub fn Document::body_html(self : Document) -> String {
  match @html_parser.query_one(self.root, "body") {
    Some(node) =>
      @html_parser.to_html(node) catch {
        _ => node.text()
      }
    None => ""
  }
}

///|
/// Returns the root node for internal traversal.
pub fn Document::root(self : Document) -> Node {
  wrap(self.root)
}

///|
/// Runs a CSS selector query against the document.
pub fn Document::query(self : Document, selector : String) -> Array[Node] {
  @html_parser.query(self.root, selector).map(wrap)
}

///|
/// Returns the first node matching a CSS selector.
pub fn Document::query_one(self : Document, selector : String) -> Node? {
  match @html_parser.query_one(self.root, selector) {
    Some(node) => Some(wrap(node))
    None => None
  }
}

///|
/// Returns the element's tag name.
pub fn Node::name(self : Node) -> String {
  self.inner.name()
}

///|
/// Returns the element's text content.
pub fn Node::text(self : Node) -> String {
  self.inner.text()
}

///|
/// Returns block-aware text with paragraph separators.
pub fn Node::content_text(self : Node) -> String {
  @html_parser.to_text(
    self.inner,
    separator="\n",
    strip=true,
    separator_blocks_only=true,
  )
}

///|
/// Renders the node as Markdown.
pub fn Node::to_markdown(self : Node) -> String {
  @html_parser.to_markdown(self.inner) catch {
    _ => self.inner.text()
  }
}

///|
/// Serializes the node back to HTML.
pub fn Node::to_html(self : Node) -> String {
  @html_parser.to_html(self.inner) catch {
    _ => self.inner.text()
  }
}

///|
/// Removes this node from its parent.
pub fn Node::remove(self : Node) -> Unit {
  match self.inner.parent() {
    Some(parent) => parent.remove_child(self.inner)
    None => ()
  }
}

///|
/// Sets an attribute value on this node.
pub fn Node::set_attr(self : Node, name : String, value : String) -> Unit {
  self.inner.attrs.set(name, Some(value))
}

///|
/// Removes an attribute from this node.
pub fn Node::remove_attr(self : Node, name : String) -> Unit {
  self.inner.attrs.remove(name)
}

///|
/// Returns the node's attribute names.
pub fn Node::attr_names(self : Node) -> Array[String] {
  let result : Array[String] = []
  for name in self.inner.attrs.keys() {
    result.push(name)
  }
  result
}

///|
fn collect_elements(node : Node, result : Array[Node]) -> Unit {
  result.push(node)
  for child in node.children() {
    if child.is_element() {
      collect_elements(child, result)
    }
  }
}

///|
fn is_url_attr(name : String) -> Bool {
  for item in [
    "href", "src", "action", "formaction", "poster", "background", "srcset",
    "xlink:href",
  ] {
    if name == item {
      return true
    }
  }
  false
}

///|
fn string_contains_any(text : String, needles : Array[String]) -> Bool {
  for needle in needles {
    match text.find(needle) {
      Some(_) => return true
      None => ()
    }
  }
  false
}

///|
fn is_unsafe_url(value : String) -> Bool {
  let lowered = value.trim().to_lower().to_owned()
  if lowered.has_prefix("javascript:") || lowered.has_prefix("vbscript:") {
    true
  } else if lowered.has_prefix("data:") {
    !string_contains_any(
      lowered,
      ["image/png", "image/jpeg", "image/gif", "image/webp"],
    )
  } else {
    string_contains_any(lowered, ["javascript:", "vbscript:"])
  }
}

///|
/// Removes boilerplate elements and unsafe attributes in place.
pub fn Node::clean(self : Node) -> Node {
  for selector in [
    "script", "style", "noscript", "iframe", "form", "nav", "aside", "footer",
  ] {
    for child in self.query(selector) {
      if !child.same(self) {
        child.remove()
      }
    }
  }
  let elements : Array[Node] = []
  collect_elements(self, elements)
  for element in elements {
    for name in element.attr_names() {
      let lowered = name.to_lower()
      if lowered.has_prefix("on") || lowered == "style" {
        element.remove_attr(name)
      } else if is_url_attr(lowered) {
        match element.attr(name) {
          Some(value) => if is_unsafe_url(value) {
            element.remove_attr(name)
          }
          None => ()
        }
      }
    }
  }
  self
}

///|
/// Removes boilerplate elements, cleans attributes, and serializes the subtree.
pub fn Node::cleaned_html(self : Node) -> String {
  self.clean().to_html()
}

///|
/// Returns an attribute value, preserving the distinction between a missing
/// attribute and an empty one.
pub fn Node::attr(self : Node, name : String) -> String? {
  match self.inner.attrs.get(name) {
    Some(Some(value)) => Some(value)
    _ => None
  }
}

///|
/// Returns whether the element has the attribute.
pub fn Node::has_attr(self : Node, name : String) -> Bool {
  match self.inner.attrs.get(name) {
    Some(_) => true
    None => false
  }
}

///|
/// Returns the element's child nodes.
pub fn Node::children(self : Node) -> Array[Node] {
  self.inner.children().map(wrap)
}

///|
/// Returns the element's parent node.
pub fn Node::parent(self : Node) -> Node? {
  match self.inner.parent() {
    Some(node) => Some(wrap(node))
    None => None
  }
}

///|
/// Runs a CSS selector query against this node's subtree.
pub fn Node::query(self : Node, selector : String) -> Array[Node] {
  @html_parser.query(self.inner, selector).map(wrap)
}

///|
/// Returns the element's class tokens.
pub fn Node::class_tokens(self : Node) -> Array[String] {
  let result : Array[String] = []
  match self.attr("class") {
    Some(value) => {
      for token in value.split(" ") {
        if token != "" {
          result.push(token.to_owned())
        }
      }
    }
    None => ()
  }
  result
}

///|
/// Returns the element's id, when present.
pub fn Node::id(self : Node) -> String? {
  self.attr("id")
}

///|
/// Returns whether this node is an element.
pub fn Node::is_element(self : Node) -> Bool {
  match self.inner.kind() {
    @html_parser.NodeKind::Element => true
    _ => false
  }
}

///|
/// Returns whether both wrappers point at the same DOM node.
pub fn Node::same(self : Node, other : Node) -> Bool {
  physical_equal(self.inner, other.inner)
}

///|
/// Returns the character length of the node's text.
pub fn Node::text_length(self : Node) -> Int {
  self.text().length()
}

///|
/// Returns the total character length of descendant link text.
pub fn Node::link_text_length(self : Node) -> Int {
  let mut total = 0
  for link in @html_parser.query(self.inner, "a") {
    total += link.text().length()
  }
  total
}

///|
/// Returns the fraction of text that lives inside links.
pub fn Node::link_density(self : Node) -> Double {
  let text_length = self.text_length()
  if text_length == 0 {
    0.0
  } else {
    self.link_text_length().to_double() / text_length.to_double()
  }
}

///|
fn is_sentence_end(ch : Char) -> Bool {
  ch == '.' || ch == '!' || ch == '?' || ch == '。' || ch == '！' || ch == '？'
}

///|
/// Counts sentence-ending punctuation in the node's text.
pub fn Node::punctuation_count(self : Node) -> Int {
  let text = self.text()
  let mut count = 0
  for ch in text {
    if is_sentence_end(ch) {
      count += 1
    }
  }
  count
}

///|
/// Returns the node's siblings, including the node itself.
pub fn Node::siblings(self : Node) -> Array[Node] {
  match self.inner.parent() {
    Some(parent) => parent.children().map(wrap)
    None => []
  }
}
