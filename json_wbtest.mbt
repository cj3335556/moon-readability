///|
test "article json includes fields" {
  let article = Article::from_parts(
    "Title",
    Some("Alice"),
    None,
    None,
    None,
    None,
    "<p>Text</p>",
    "Text",
    "Text",
    4,
  )
  let json = article_to_json_string(article)
  assert_true(contains(json, "\"title\":\"Title\""))
  assert_true(contains(json, "\"byline\":\"Alice\""))
  assert_true(contains(json, "\"site_name\":null"))
  assert_true(contains(json, "\"length\":4"))
}
