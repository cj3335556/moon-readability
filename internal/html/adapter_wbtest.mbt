///|
fn parse_ok(html : String) -> Document {
  parse(html) catch {
    _ => abort("unexpected parse error")
  }
}

///|
test "parse minimal document" {
  let doc = parse_ok("<p>hello</p>")
  assert_eq(doc.body_text(), "hello")
}

///|
test "parse title and body" {
  let doc = parse_ok(
    "<html><head><title>Demo</title></head><body><p>Hello</p></body></html>",
  )
  assert_eq(doc.title(), "Demo")
  assert_eq(doc.body_text(), "Hello")
}
