///|
fn has_token(tokens : Array[String], value : String) -> Bool {
  for token in tokens {
    if token == value {
      return true
    }
  }
  false
}

///|
test "class tokens and id" {
  let doc = parse_ok(
    "<div id=\"main\" class=\"post-content wide\"><p>Hello</p></div>",
  )
  let div = match doc.query_one("div") {
    Some(node) => node
    None => abort("missing div")
  }
  assert_eq(div.id(), Some("main"))
  assert_eq(div.class_tokens().length(), 2)
  assert_true(has_token(div.class_tokens(), "post-content"))
  assert_true(div.is_element())
}

///|
test "text length and link density" {
  let doc = parse_ok(
    "<div><p>Hello world</p><p><a href=\"/a\">Link text</a></p></div>",
  )
  let div = match doc.query_one("div") {
    Some(node) => node
    None => abort("missing div")
  }
  assert_eq(div.text_length(), div.text().length())
  assert_eq(div.query("a").length(), 1)
  assert_true(div.link_text_length() > 0)
  assert_true(div.link_density() > 0.0)
}

///|
test "punctuation count" {
  let doc = parse_ok("<p>One. Two! Three?</p>")
  let paragraph = match doc.query_one("p") {
    Some(node) => node
    None => abort("missing paragraph")
  }
  assert_eq(paragraph.punctuation_count(), 3)
}

///|
test "siblings include self and peers" {
  let doc = parse_ok("<div><p>One</p><p>Two</p></div>")
  let paragraph = match doc.query_one("p") {
    Some(node) => node
    None => abort("missing paragraph")
  }
  assert_eq(paragraph.siblings().length(), 2)
}
