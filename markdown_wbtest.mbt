///|
test "renders headings links and lists" {
  let article = extract_article(
    "<article><h1>Title</h1><p>Hello <a href=\"https://example.com\">link</a>.</p><ul><li>One</li><li>Two</li></ul></article>",
  ) catch {
    _ => abort("unexpected extraction error")
  }
  let markdown = article_to_markdown(article) catch {
    _ => abort("unexpected markdown error")
  }
  assert_true(contains(markdown, "Title"))
  assert_true(contains(markdown, "[link](https://example.com)"))
  assert_true(contains(markdown, "One"))
  assert_true(contains(markdown, "Two"))
}

///|
test "markdown falls back to text for empty html" {
  let article = Article::from_parts(
    "Title",
    None,
    None,
    None,
    None,
    None,
    "",
    "Plain text",
    "Plain text",
    10,
  )
  let markdown = article_to_markdown(article) catch {
    _ => abort("unexpected markdown error")
  }
  assert_eq(markdown, "Plain text")
}
