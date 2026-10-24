///|
test "removes scripts unsafe attributes and javascript urls" {
  let article = extract_article(
    "<article><p onclick=\"alert(1)\">Text</p><script>alert(1)</script><a href=\"javascript:alert(1)\">Link</a><img src=\"/img.png\" onerror=\"alert(1)\"></article>",
  ) catch {
    _ => abort("unexpected extraction error")
  }
  assert_true(contains(article.content_text, "Text"))
  assert_true(!contains(article.content_html, "script"))
  assert_true(!contains(article.content_html, "onclick"))
  assert_true(!contains(article.content_html, "onerror"))
  assert_true(!contains(article.content_html, "javascript:"))
}

///|
test "resolves relative urls against base" {
  let article = extract_article(
    "<article><p>Text</p><a href=\"/post/1\">Link</a><img src=\"img.png\"></article>",
    options=ExtractionOptions::new(
      base_url="https://example.com/blog/page.html",
    ),
  ) catch {
    _ => abort("unexpected extraction error")
  }
  assert_true(contains(article.content_html, "https://example.com/post/1"))
  assert_true(
    contains(article.content_html, "https://example.com/blog/img.png"),
  )
}

///|
test "resolves srcset candidates" {
  let article = extract_article(
    "<article><p>Text</p><img srcset=\"a.png 1x, b.png 2x\"></article>",
    options=ExtractionOptions::new(base_url="https://example.com/"),
  ) catch {
    _ => abort("unexpected extraction error")
  }
  assert_true(contains(article.content_html, "https://example.com/a.png 1x"))
  assert_true(contains(article.content_html, "https://example.com/b.png 2x"))
}

///|
test "removes nested navigation and footer" {
  let article = extract_article(
    "<article><p>Body text.</p><nav>Menu</nav><footer>Footer</footer></article>",
  ) catch {
    _ => abort("unexpected extraction error")
  }
  assert_true(contains(article.content_text, "Body text"))
  assert_true(!contains(article.content_text, "Menu"))
  assert_true(!contains(article.content_text, "Footer"))
}
