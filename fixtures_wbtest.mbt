///|
fn read_fixture(name : String) -> String {
  @fs.read_file_to_string("testdata/" + name) catch {
    _ => abort("failed to read fixture: " + name)
  }
}

///|
fn extract_fixture(name : String) -> Article {
  extract_article(read_fixture(name)) catch {
    _ => abort("failed to extract fixture: " + name)
  }
}

///|
test "extracts blog fixture" {
  let article = extract_fixture("blog.html")
  assert_eq(article.title, "Building a small parser")
  assert_true(contains(article.content_text, "tokenization"))
  assert_true(!contains(article.content_text, "Sidebar"))
  assert_true(!contains(article.content_text, "Footer links"))
}

///|
test "extracts news fixture" {
  let article = extract_fixture("news.html")
  assert_eq(article.title, "City opens a new library")
  assert_eq(article.byline, Some("News Desk"))
  assert_eq(article.published_time, Some("2026-10-24T09:30:00Z"))
  assert_true(contains(article.content_text, "public library"))
  assert_true(!contains(article.content_text, "Related stories"))
}

///|
test "extracts docs fixture" {
  let article = extract_fixture("docs.html")
  assert_true(contains(article.content_text, "Parser API"))
  assert_true(contains(article.content_text, "parse(html)"))
}

///|
test "extracts chinese fixture" {
  let article = extract_fixture("chinese.html")
  assert_eq(article.language, Some("zh-CN"))
  assert_true(contains(article.content_text, "正文提取"))
  assert_true(!contains(article.content_text, "页脚信息"))
}

///|
test "extracts malformed fixture" {
  let article = extract_fixture("malformed.html")
  assert_true(contains(article.content_text, "Another paragraph"))
}

///|
test "extracts empty body fixture" {
  let article = extract_fixture("empty_body.html")
  assert_eq(article.title, "Empty body")
  assert_eq(article.length, 0)
  assert_eq(article.content_text, "")
}

///|
test "extracts link heavy fixture" {
  let article = extract_fixture("link_heavy.html")
  assert_true(contains(article.content_text, "actual article text"))
  assert_true(!contains(article.content_text, "Epsilon"))
}

///|
test "extracts json-ld fixture" {
  let article = extract_fixture("json_ld.html")
  assert_eq(article.title, "JSON-LD article")
  assert_eq(article.byline, Some("JSON Author"))
  assert_eq(article.published_time, Some("2026-10-25"))
  assert_eq(article.site_name, Some("JSON Site"))
  assert_eq(article.language, Some("en"))
  assert_true(contains(article.content_text, "JSON-LD body text"))
}
