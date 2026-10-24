///|
fn optional_string_json(value : String?) -> Json {
  match value {
    Some(text) => Json::string(text)
    None => Json::null()
  }
}

///|
/// Converts an article to a JSON value.
pub fn article_to_json(article : Article) -> Json {
  let fields : Map[String, Json] = Map([])
  fields.set("title", Json::string(article.title))
  fields.set("byline", optional_string_json(article.byline))
  fields.set("site_name", optional_string_json(article.site_name))
  fields.set("published_time", optional_string_json(article.published_time))
  fields.set("language", optional_string_json(article.language))
  fields.set("canonical_url", optional_string_json(article.canonical_url))
  fields.set("content_html", Json::string(article.content_html))
  fields.set("content_text", Json::string(article.content_text))
  fields.set("excerpt", Json::string(article.excerpt))
  fields.set("length", Json::number(article.length.to_double()))
  Json::object(fields)
}

///|
/// Converts an article to a JSON string.
pub fn article_to_json_string(article : Article) -> String {
  article_to_json(article).stringify()
}
