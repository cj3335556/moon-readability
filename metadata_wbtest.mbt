///|
fn metadata_ok(html : String) -> Metadata {
  extract_metadata(html) catch {
    _ => abort("unexpected metadata extraction error")
  }
}

///|
test "basic metadata" {
  let meta = metadata_ok(
    "<html lang=\"en\"><head><title>Basic title</title><meta name=\"author\" content=\"Alice\"><link rel=\"canonical\" href=\"https://example.com/basic\"></head><body><h1>Heading</h1></body></html>",
  )
  assert_eq(meta.title, Some("Basic title"))
  assert_eq(meta.byline, Some("Alice"))
  assert_eq(meta.language, Some("en"))
  assert_eq(meta.canonical_url, Some("https://example.com/basic"))
}

///|
test "open graph wins over title" {
  let meta = metadata_ok(
    "<html><head><title>HTML title</title><meta property=\"og:title\" content=\"OG title\"><meta property=\"og:site_name\" content=\"Example\"><meta property=\"article:published_time\" content=\"2026-10-24T10:00:00Z\"></head><body></body></html>",
  )
  assert_eq(meta.title, Some("OG title"))
  assert_eq(meta.site_name, Some("Example"))
  assert_eq(meta.published_time, Some("2026-10-24T10:00:00Z"))
}

///|
test "sparse metadata returns none" {
  let meta = metadata_ok("<html><body><p>No metadata</p></body></html>")
  assert_true(meta.title is None)
  assert_true(meta.byline is None)
  assert_true(meta.site_name is None)
  assert_true(meta.published_time is None)
  assert_true(meta.language is None)
  assert_true(meta.canonical_url is None)
}

///|
test "relative canonical uses base url" {
  let meta = extract_metadata(
    "<html><head><link rel=\"canonical\" href=\"/post/1\"></head><body></body></html>",
    base_url="https://example.com",
  ) catch {
    _ => abort("unexpected metadata extraction error")
  }
  assert_eq(meta.canonical_url, Some("https://example.com/post/1"))
}

///|
test "baseline article uses body text" {
  let article = extract_article(
    "<html><head><title>Title</title></head><body><p>Hello world</p></body></html>",
  ) catch {
    _ => abort("unexpected article extraction error")
  }
  assert_eq(article.title, "Title")
  assert_true(contains(article.content_text, "Hello world"))
  assert_true(article.length >= 11)
}
