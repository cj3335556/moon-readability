///|
fn last_slash(text : StringView) -> Int32 {
  let mut index = -1
  let mut position = 0
  for ch in text {
    if ch == '/' {
      index = position
    }
    position += 1
  }
  index
}

///|
fn has_scheme(value : String) -> Bool {
  match value.split_once(":") {
    Some((scheme, _)) =>
      if scheme == "" {
        false
      } else {
        !contains(scheme.to_owned(), "/")
      }
    None => false
  }
}

///|
fn split_suffix(value : String) -> (String, String) {
  let mut end = value.length()
  let mut index = 0
  for ch in value {
    if ch == '?' || ch == '#' {
      end = index
      break
    }
    index += 1
  }
  (value[:end].to_owned(), value.view(start_offset=end).to_owned())
}

///|
fn normalize_path(path : String) -> String {
  let absolute = path.has_prefix("/")
  let trailing = path.has_suffix("/")
  let segments : Array[String] = []
  for part in path.split("/") {
    let segment = part.to_owned()
    if segment == "" || segment == "." {
      // Skip empty and current-directory segments.
    } else if segment == ".." {
      if segments.length() > 0 {
        ignore(segments.pop())
      }
    } else {
      segments.push(segment)
    }
  }
  let joined = segments.join("/")
  let base = if absolute { "/" + joined } else { joined }
  if trailing && base != "" && base != "/" {
    base + "/"
  } else {
    base
  }
}

///|
fn normalize_url(url : String) -> String {
  match url.split_once("://") {
    Some((scheme, rest)) =>
      match rest.split_once("/") {
        Some((host, path)) => {
          let normalized = normalize_path("/" + path.to_owned())
          scheme.to_owned() + "://" + host.to_owned() + normalized
        }
        None => url
      }
    None => url
  }
}

///|
fn resolve_url(value : String, base_url : String?) -> String {
  if value == "" {
    return value
  }
  if contains(value, "://") || has_scheme(value) {
    return value
  }
  let (value_path, value_suffix) = split_suffix(value)
  if value_path == "" {
    return match base_url {
      Some(base) => base + value_suffix
      None => value
    }
  }
  if value_path.has_prefix("//") {
    return match base_url {
      Some(base) =>
        match base.split_once("://") {
          Some((scheme, _)) =>
            scheme.to_owned() + ":" + value_path + value_suffix
          None => value
        }
      None => value
    }
  }
  match base_url {
    Some(base) => {
      let (base_path, _) = split_suffix(base)
      match base_path.split_once("://") {
        Some((scheme, rest)) =>
          match rest.split_once("/") {
            Some((host, path)) => {
              let origin = scheme.to_owned() + "://" + host.to_owned()
              let resolved = if value_path.has_prefix("/") {
                origin + value_path
              } else {
                let directory = if path == "" {
                  origin + "/"
                } else {
                  let last = last_slash(path)
                  if last >= 0 {
                    origin + "/" + path.view(end_offset=last + 1).to_owned()
                  } else {
                    origin + "/"
                  }
                }
                directory + value_path
              }
              normalize_url(resolved) + value_suffix
            }
            None => {
              let origin = scheme.to_owned() + "://" + rest.to_owned()
              normalize_url(
                origin + "/" + value_path.trim_start(chars="/").to_owned(),
              ) +
              value_suffix
            }
          }
        None => value
      }
    }
    None => value
  }
}

///|
fn resolve_srcset(value : String, base_url : String?) -> String {
  let result : Array[String] = []
  for candidate in value.split(",") {
    let trimmed = candidate.trim().to_owned()
    if trimmed != "" {
      match trimmed.split_once(" ") {
        Some((url, descriptor)) => {
          let resolved = resolve_url(url.to_owned(), base_url)
          let desc = descriptor.trim().to_owned()
          if desc != "" {
            result.push(resolved + " " + desc)
          } else {
            result.push(resolved)
          }
        }
        None => result.push(resolve_url(trimmed, base_url))
      }
    }
  }
  result.join(", ")
}

///|
fn resolve_attr(node : @html.Node, name : String, base_url : String?) -> Unit {
  match node.attr(name) {
    Some(value) => node.set_attr(name, resolve_url(value, base_url))
    None => ()
  }
}

///|
fn resolve_content_urls(nodes : Array[@html.Node], base_url : String?) -> Unit {
  for node in nodes {
    for link in node.query("a") {
      resolve_attr(link, "href", base_url)
    }
    for image in node.query("img") {
      resolve_attr(image, "src", base_url)
      match image.attr("srcset") {
        Some(value) => image.set_attr("srcset", resolve_srcset(value, base_url))
        None => ()
      }
    }
    for source in node.query("source") {
      resolve_attr(source, "src", base_url)
      match source.attr("srcset") {
        Some(value) =>
          source.set_attr("srcset", resolve_srcset(value, base_url))
        None => ()
      }
    }
  }
}
