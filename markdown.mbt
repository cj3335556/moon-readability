///|
/// Renders an article's cleaned HTML as Markdown.
pub fn article_to_markdown(article : Article) -> String raise ExtractionError {
  if article.content_html == "" {
    return article.content_text
  }
  let doc = @html.parse(article.content_html) catch {
    error =>
      raise ParseFailed(
        "failed to parse article HTML: " + @html.format_error(error),
      )
  }
  match doc.body() {
    Some(node) => node.to_markdown()
    None => article.content_text
  }
}
