///|
/// A parsed HTML document owned by the extraction pipeline.
pub struct Document {
  root : @html_parser.Node
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
/// Returns the underlying root node for internal traversal.
pub fn Document::root(self : Document) -> @html_parser.Node {
  self.root
}
