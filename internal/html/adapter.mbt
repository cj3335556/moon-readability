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
/// Returns an attribute value, preserving the distinction between a missing
/// attribute and an empty one.
pub fn Node::attr(self : Node, name : String) -> String? {
  match self.inner.attrs().get(name) {
    Some(Some(value)) => Some(value)
    _ => None
  }
}

///|
/// Returns whether the element has the attribute.
pub fn Node::has_attr(self : Node, name : String) -> Bool {
  match self.inner.attrs().get(name) {
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
