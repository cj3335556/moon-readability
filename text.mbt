///|
fn is_sentence_end_char(ch : Char) -> Bool {
  ch == '.' ||
  ch == '!' ||
  ch == '?' ||
  ch == '。' ||
  ch == '！' ||
  ch == '？'
}

///|
fn normalize_text(text : String) -> String {
  let lines : Array[String] = []
  for line in text.split("\n") {
    let trimmed = line.trim().to_owned()
    if trimmed != "" {
      lines.push(trimmed)
    }
  }
  lines.join("\n")
}

///|
fn make_excerpt(text : String, limit : Int32) -> String {
  if limit <= 0 {
    return ""
  }
  if text.length() <= limit {
    return text
  }
  let prefix = text[:limit].to_owned()
  let mut cut = -1
  let mut index = 0
  for ch in prefix {
    if is_sentence_end_char(ch) {
      cut = index + 1
    }
    index += 1
  }
  if cut > 0 {
    prefix[:cut].to_owned()
  } else {
    prefix
  }
}
