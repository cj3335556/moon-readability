///|
test "cli outputs json by default" {
  let result = run_cli_args(["page.html"], fn(_path) {
    Some("<article><p>Hello.</p></article>")
  })
  assert_eq(result.exit_code, 0)
  assert_true(contains(result.stdout, "\"content_text\""))
}

///|
test "cli outputs markdown" {
  let result = run_cli_args(["page.html", "--markdown"], fn(_path) {
    Some("<article><h1>Title</h1><p>Text</p></article>")
  })
  assert_eq(result.exit_code, 0)
  assert_true(contains(result.stdout, "Text"))
}

///|
test "cli reports missing path" {
  let result = run_cli_args([], fn(_path) { None })
  assert_eq(result.exit_code, 2)
  assert_true(contains(result.stderr, "missing input path"))
}

///|
test "cli reports unreadable file" {
  let result = run_cli_args(["missing.html"], fn(_path) { None })
  assert_eq(result.exit_code, 1)
  assert_true(contains(result.stderr, "failed to read"))
}

///|
test "cli reports empty input" {
  let result = run_cli_args(["empty.html"], fn(_path) { Some("") })
  assert_eq(result.exit_code, 1)
  assert_true(contains(result.stderr, "input is empty"))
}

///|
test "cli help and version" {
  let help = run_cli_args(["--help"], fn(_path) { None })
  assert_eq(help.exit_code, 0)
  assert_true(contains(help.stdout, "Usage:"))
  let version_result = run_cli_args(["--version"], fn(_path) { None })
  assert_eq(version_result.exit_code, 0)
  assert_eq(version_result.stdout, version() + "\n")
}

///|
test "cli parses base url" {
  let result = run_cli_args(
    ["page.html", "--base-url", "https://example.com"],
    fn(_path) {
      Some("<article><p>Text</p><a href=\"/post\">Link</a></article>")
    },
  )
  assert_eq(result.exit_code, 0)
  assert_true(contains(result.stdout, "https://example.com/post"))
}
