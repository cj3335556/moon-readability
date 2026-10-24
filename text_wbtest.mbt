///|
test "preserves paragraph breaks" {
  let article = extract_article("<article><p>One.</p><p>Two.</p></article>") catch {
    _ => abort("unexpected extraction error")
  }
  assert_true(contains(article.content_text, "One."))
  assert_true(contains(article.content_text, "Two."))
  assert_true(!contains(article.content_text, "One.Two."))
}

///|
test "handles chinese text" {
  let article = extract_article(
    "<article><p>第一段。第二段。</p></article>",
  ) catch {
    _ => abort("unexpected extraction error")
  }
  assert_true(contains(article.content_text, "第一段"))
  assert_true(article.length >= 8)
  assert_true(article.excerpt.length() <= article.length)
}

///|
test "excerpt stops at sentence boundary" {
  let article = extract_article(
    "<article><p>First sentence. Second sentence is longer.</p></article>",
    options=ExtractionOptions::new(max_excerpt_chars=16),
  ) catch {
    _ => abort("unexpected extraction error")
  }
  assert_eq(article.excerpt, "First sentence.")
}
