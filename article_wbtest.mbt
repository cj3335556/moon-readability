///|
test "article model holds fields" {
  let article = Article::from_parts(
    "Example",
    None,
    None,
    None,
    None,
    None,
    "<p>Example</p>",
    "Example",
    "Example",
    7,
  )
  assert_eq(article.title, "Example")
  assert_eq(article.content_text, "Example")
  assert_eq(article.length, 7)
}
