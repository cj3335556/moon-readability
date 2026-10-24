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
fn char_count(text : String) -> Int32 {
  let mut count = 0
  for _ in text {
    count += 1
  }
  count
}

///|
fn take_chars(text : String, limit : Int32) -> String {
  let mut result = ""
  let mut count = 0
  for ch in text {
    if count >= limit {
      break
    }
    result = result + ch.to_string()
    count += 1
  }
  result
}

///|
fn make_excerpt(text : String, limit : Int32) -> String {
  if limit <= 0 {
    return ""
  }
  if char_count(text) <= limit {
    return text
  }
  let prefix = take_chars(text, limit)
  let mut cut = -1
  let mut index = 0
  for ch in prefix {
    if is_sentence_end_char(ch) {
      cut = index + 1
    }
    index += 1
  }
  if cut > 0 {
    take_chars(prefix, cut)
  } else {
    prefix
  }
}
