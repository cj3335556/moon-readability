///|
fn contains(text : String, needle : String) -> Bool {
  match text.find(needle) {
    Some(_) => true
    None => false
  }
}

///|
fn meta_by_name(doc : @html.Document, name : String) -> String? {
  for meta in doc.query("meta") {
    match meta.attr("name") {
      Some(value) => {
        if value == name {
          match meta.attr("content") {
            Some(content) => if content != "" { return Some(content) }
            None => ()
          }
        }
      }
      None => ()
    }
  }
  None
}

///|
fn meta_by_property(doc : @html.Document, property : String) -> String? {
  for meta in doc.query("meta") {
    match meta.attr("property") {
      Some(value) => {
        if value == property {
          match meta.attr("content") {
            Some(content) => if content != "" { return Some(content) }
            None => ()
          }
        }
      }
      None => ()
    }
  }
  None
}

///|
fn option_text(node : @html.Node?) -> String? {
  match node {
    Some(value) => {
      let text = value.text().trim().to_owned()
      if text != "" {
        Some(text)
      } else {
        None
      }
    }
    None => None
  }
}

///|
fn option_attr(node : @html.Node?, name : String) -> String? {
  match node {
    Some(value) =>
      match value.attr(name) {
        Some(text) => if text != "" { Some(text) } else { None }
        None => None
      }
    None => None
  }
}

///|
fn first_non_empty(values : Array[String?]) -> String? {
  for value in values {
    match value {
      Some(text) => if text != "" { return Some(text) }
      None => ()
    }
  }
  None
}

///|
fn domain_from_url(url : String?) -> String? {
  match url {
    Some(value) => {
      let without_scheme = match value.split_once("://") {
        Some((_, rest)) => rest
        None => value.view()
      }
      let host = match without_scheme.split_once("/") {
        Some((host, _)) => host
        None => without_scheme
      }
      if host != "" {
        Some(host.to_owned())
      } else {
        None
      }
    }
    None => None
  }
}

///|
fn canonical_url(doc : @html.Document, base_url : String?) -> String? {
  for link in doc.query("link") {
    match link.attr("rel") {
      Some(rel) => {
        if rel == "canonical" || contains(rel, "canonical") {
          match link.attr("href") {
            Some(href) => if href != "" { return Some(resolve_url(href, base_url)) }
            None => ()
          }
        }
      }
      None => ()
    }
  }
  None
}

///|
fn metadata_from_document(doc : @html.Document, base_url : String?) -> Metadata {
  let title = first_non_empty([
    meta_by_property(doc, "og:title"),
    meta_by_name(doc, "twitter:title"),
    option_text(doc.query_one("title")),
    option_text(doc.query_one("h1")),
  ])
  let byline = first_non_empty([
    meta_by_name(doc, "author"),
    meta_by_property(doc, "article:author"),
  ])
  let site_name = first_non_empty([
    meta_by_property(doc, "og:site_name"),
    domain_from_url(base_url),
  ])
  let published_time = first_non_empty([
    meta_by_property(doc, "article:published_time"),
    meta_by_name(doc, "date"),
  ])
  let language = first_non_empty([
    option_attr(doc.query_one("html"), "lang"),
    meta_by_name(doc, "content-language"),
  ])
  let canonical = canonical_url(doc, base_url)
  {
    title,
    byline,
    site_name,
    published_time,
    language,
    canonical_url: canonical,
  }
}

///|
/// Extracts metadata from an HTML document.
pub fn extract_metadata(
  html : String,
  base_url? : String,
) -> Metadata raise ExtractionError {
  let doc = @html.parse(html) catch {
    _ => raise ParseFailed("failed to parse HTML")
  }
  metadata_from_document(doc, base_url)
}

///|
/// Extracts a baseline article using metadata and the whole body.
///
/// Content selection and cleaning replace the body baseline in later
/// increments.
pub fn extract_article(
  html : String,
  options? : ExtractionOptions,
) -> Article raise ExtractionError {
  let opts = match options {
    Some(value) => value
    None => ExtractionOptions::new()
  }
  let doc = @html.parse(html) catch {
    _ => raise ParseFailed("failed to parse HTML")
  }
  let metadata = metadata_from_document(doc, opts.base_url)
  let selected_nodes = select_content_nodes(doc)
  let content_nodes = if selected_nodes.length() > 0 {
    selected_nodes
  } else {
    match doc.body() {
      Some(node) => [node]
      None => []
    }
  }
  resolve_content_urls(content_nodes, opts.base_url)
  let text_parts : Array[String] = []
  let html_parts : Array[String] = []
  for node in content_nodes {
    let cleaned = node.clean()
    html_parts.push(cleaned.to_html())
    text_parts.push(cleaned.text())
  }
  let content_text = text_parts.join("\n")
  let content_html = html_parts.join("")
  let title = match metadata.title {
    Some(value) => value
    None => doc.title()
  }
  let excerpt = if content_text.length() > opts.max_excerpt_chars {
    content_text[:opts.max_excerpt_chars].to_owned()
  } else {
    content_text
  }
  Article::from_parts(
    title,
    metadata.byline,
    metadata.site_name,
    metadata.published_time,
    metadata.language,
    metadata.canonical_url,
    content_html,
    content_text,
    excerpt,
    content_text.length(),
  )
}
