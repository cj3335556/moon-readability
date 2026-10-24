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
fn resolve_url(value : String, base_url : String?) -> String {
  if value == "" {
    return value
  }
  if contains(value, "://") || has_scheme(value) {
    return value
  }
  if value.has_prefix("//") {
    return match base_url {
      Some(base) =>
        match base.split_once("://") {
          Some((scheme, _)) => scheme.to_owned() + ":" + value
          None => value
        }
      None => value
    }
  }
  if value.has_prefix("#") {
    return match base_url {
      Some(base) => base + value
      None => value
    }
  }
  match base_url {
    Some(base) =>
      match base.split_once("://") {
        Some((scheme, rest)) =>
          match rest.split_once("/") {
            Some((host, path)) => {
              let origin = scheme.to_owned() + "://" + host.to_owned()
              if value.has_prefix("/") {
                origin + value
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
                directory + value
              }
            }
            None => {
              let origin = scheme.to_owned() + "://" + rest.to_owned()
              origin + "/" + value.trim_start(chars="/").to_owned()
            }
          }
        None => value
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
