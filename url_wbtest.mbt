///|
test "normalizes parent segments" {
  let article = extract_article(
    "<article><p>Text</p><img src=\"../img/logo.png\"></article>",
    options=ExtractionOptions::new(base_url="https://example.com/a/b/page.html"),
  ) catch {
    _ => abort("unexpected extraction error")
  }
  assert_true(
    contains(article.content_html, "https://example.com/a/img/logo.png"),
  )
}

///|
test "keeps query and fragment while resolving" {
  let article = extract_article(
    "<article><p>Text</p><a href=\"next?x=1#top\">Next</a></article>",
    options=ExtractionOptions::new(
      base_url="https://example.com/a/page.html?ref=1#frag",
    ),
  ) catch {
    _ => abort("unexpected extraction error")
  }
  assert_true(
    contains(article.content_html, "https://example.com/a/next?x=1#top"),
  )
}

///|
test "normalizes parent segments in root relative links" {
  let article = extract_article(
    "<article><p>Text</p><a href=\"/a/../b\">B</a></article>",
    options=ExtractionOptions::new(base_url="https://example.com/x/y"),
  ) catch {
    _ => abort("unexpected extraction error")
  }
  assert_true(contains(article.content_html, "https://example.com/b"))
}
