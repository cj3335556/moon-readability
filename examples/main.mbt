///|
fn main {
  let html = "<html lang=\"en\"><head><title>Example article</title><meta name=\"author\" content=\"Example Author\"></head><body><nav><a href=\"/\">Home</a></nav><article><h1>Example article</h1><p>This is a short example of article extraction. It keeps the body and drops the navigation.</p></article><footer>Footer</footer></body></html>"
  let article = @readability.extract_article(html) catch {
    _ => abort("failed to extract example article")
  }
  println("Title: " + article.title)
  println("Text: " + article.content_text)
  let markdown = @readability.article_to_markdown(article) catch {
    _ => abort("failed to render example markdown")
  }
  println("Markdown:")
  println(markdown)
}
