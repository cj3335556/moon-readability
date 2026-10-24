///|
test "empty input" {
  let article = extract_article("") catch {
    _ => abort("unexpected extraction error")
  }
  assert_eq(article.length, 0)
  assert_eq(article.content_text, "")
}

///|
test "deeply nested markup" {
  let mut html = "<article>"
  for _ in 0..<50 {
    html = html + "<div>"
  }
  html = html + "<p>Deep text.</p>"
  for _ in 0..<50 {
    html = html + "</div>"
  }
  html = html + "</article>"
  let article = extract_article(html) catch {
    _ => abort("unexpected extraction error")
  }
  assert_true(contains(article.content_text, "Deep text"))
}

///|
test "duplicate ids" {
  let article = extract_article(
    "<article><p id=\"x\">One.</p><p id=\"x\">Two.</p></article>",
  ) catch {
    _ => abort("unexpected extraction error")
  }
  assert_true(contains(article.content_text, "One."))
  assert_true(contains(article.content_text, "Two."))
}

///|
test "missing title" {
  let article = extract_article("<article><p>Text.</p></article>") catch {
    _ => abort("unexpected extraction error")
  }
  assert_eq(article.title, "")
}

///|
test "long document performance guard" {
  let mut html = "<article>"
  for index in 0..<300 {
    html = html + "<p>Paragraph " + index.to_string() + " with some text.</p>"
  }
  html = html + "</article>"
  let start = @env.now()
  let article = extract_article(html) catch {
    _ => abort("unexpected extraction error")
  }
  let elapsed = @env.now() - start
  assert_true(article.length > 0)
  assert_true(elapsed < 15000)
}
