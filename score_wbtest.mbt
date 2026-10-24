///|
fn parse_document(html : String) -> @html.Document {
  @html.parse(html) catch {
    _ => abort("unexpected parse error")
  }
}

///|
fn require_node(doc : @html.Document, selector : String) -> @html.Node {
  match doc.query_one(selector) {
    Some(node) => node
    None => abort("missing node: " + selector)
  }
}

///|
test "article outranks navigation" {
  let doc = parse_document(
    "<html><body><nav><a href=\"/\">Home</a><a href=\"/about\">About</a></nav><article><p>First paragraph with enough text to score well. It has multiple sentences.</p><p>Second paragraph adds more content and detail.</p></article><footer>Footer</footer></body></html>",
  )
  let article_score = score_node(require_node(doc, "article"))
  let nav_score = score_node(require_node(doc, "nav"))
  assert_true(article_score.total > nav_score.total)
  assert_true(article_score.text_score > 0)
  assert_true(nav_score.link_penalty > 0)
}

///|
test "link-heavy node is penalized" {
  let doc = parse_document(
    "<div><a href=\"/a\">One</a><a href=\"/b\">Two</a></div><div><p>Plain text with a sentence. Another sentence.</p></div>",
  )
  let divs = doc.query("div")
  assert_eq(divs.length(), 2)
  let link_heavy = score_node(divs[0])
  let text_heavy = score_node(divs[1])
  assert_true(text_heavy.total > link_heavy.total)
  assert_true(link_heavy.link_penalty > text_heavy.link_penalty)
}

///|
test "class hints affect score" {
  let doc = parse_document(
    "<div class=\"post-content\"><p>Text.</p></div><div class=\"sidebar\"><p>Text.</p></div>",
  )
  let divs = doc.query("div")
  assert_eq(divs.length(), 2)
  let content_score = score_node(divs[0])
  let sidebar_score = score_node(divs[1])
  assert_true(content_score.class_score > sidebar_score.class_score)
}

///|
test "score document collects candidates" {
  let doc = parse_document(
    "<article><p>Some article text.</p></article><aside>Sidebar</aside>",
  )
  let scored = score_document(doc)
  assert_true(scored.length() > 0)
}

///|
test "selects article over navigation" {
  let doc = parse_document(
    "<nav><a href=\"/\">Home</a></nav><article><p>Article body with a full sentence. Another sentence.</p></article><footer>Footer</footer>",
  )
  let selected = match select_main_node(doc) {
    Some(node) => node
    None => abort("missing main node")
  }
  assert_eq(selected.name(), "article")
}

///|
test "selection returns none when no candidate exists" {
  let doc = parse_document("<html><body></body></html>")
  assert_true(select_main_node(doc) is None)
}

///|
test "merges sibling content blocks" {
  let doc = parse_document(
    "<div class=\"post-content\"><p>First content block with enough text to pass the threshold. It has two sentences.</p></div><div class=\"post-content\"><p>Second content block with enough text to pass the threshold. It also has two sentences.</p></div><div class=\"sidebar\"><p>Sidebar text that should not be merged into the article body.</p></div>",
  )
  let nodes = select_content_nodes(doc)
  assert_eq(nodes.length(), 2)
  assert_true(contains(nodes[0].text(), "First content block"))
  assert_true(contains(nodes[1].text(), "Second content block"))
}

///|
test "excludes navigation and footer siblings" {
  let doc = parse_document(
    "<article><p>Article text with enough content to be selected. Another sentence.</p></article><nav><a href=\"/\">Home</a></nav><footer>Footer</footer>",
  )
  let nodes = select_content_nodes(doc)
  assert_eq(nodes.length(), 1)
  assert_eq(nodes[0].name(), "article")
}

///|
test "content selection empty for template-only document" {
  let doc = parse_document("<html><body></body></html>")
  assert_eq(select_content_nodes(doc).length(), 0)
}
