///|
fn manifest_version() -> String {
  let manifest = @fs.read_file_to_string("moon.mod") catch {
    _ => abort("failed to read moon.mod")
  }
  for line in manifest.split("\n") {
    let trimmed = line.trim()
    if trimmed.has_prefix("version") {
      match trimmed.split_once("=") {
        Some((_, value)) => {
          let raw = value.trim()
          let unquoted = match raw.strip_prefix("\"") {
            Some(rest) =>
              match rest.strip_suffix("\"") {
                Some(inner) => inner
                None => rest
              }
            None => raw
          }
          return unquoted.to_owned()
        }
        None => ()
      }
    }
  }
  abort("version not found in moon.mod")
}

///|
test "version matches moon.mod" {
  assert_eq(version(), manifest_version())
}
