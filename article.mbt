///|
/// The result of extracting an article from HTML.
pub struct Article {
  title : String
  byline : String?
  site_name : String?
  published_time : String?
  language : String?
  canonical_url : String?
  content_html : String
  content_text : String
  excerpt : String
  length : Int32
}

///|
/// Builds an article from its parts.
pub fn Article::from_parts(
  title : String,
  byline : String?,
  site_name : String?,
  published_time : String?,
  language : String?,
  canonical_url : String?,
  content_html : String,
  content_text : String,
  excerpt : String,
  length : Int32,
) -> Article {
  {
    title,
    byline,
    site_name,
    published_time,
    language,
    canonical_url,
    content_html,
    content_text,
    excerpt,
    length,
  }
}

///|
/// Metadata discovered in the document head.
pub struct Metadata {
  title : String?
  byline : String?
  site_name : String?
  published_time : String?
  language : String?
  canonical_url : String?
}

///|
/// Options that control extraction.
pub struct ExtractionOptions {
  base_url : String?
  max_excerpt_chars : Int32
}

///|
/// Creates extraction options with a 200-character excerpt by default.
pub fn ExtractionOptions::new(
  base_url? : String,
  max_excerpt_chars~ : Int32 = 200,
) -> ExtractionOptions {
  { base_url, max_excerpt_chars, }
}

///|
/// Errors raised while parsing or extracting a document.
pub(all) suberror ExtractionError {
  ParseFailed(String)
  Usage(String)
}
