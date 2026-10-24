///|
/// Output formats supported by the command-line interface.
pub(all) enum OutputFormat {
  Json
  Markdown
  Text
}

///|
/// Parsed command-line options.
pub struct CliOptions {
  path : String
  format : OutputFormat
  base_url : String?
}

///|
/// The result of a CLI run, kept separate from the executable for testing.
pub struct CliResult {
  stdout : String
  stderr : String
  exit_code : Int32
}

///|
/// Returns the command-line help text.
pub fn cli_help() -> String {
  "Usage: moon-readability <file.html> [--json|--markdown|--text] [--base-url <url>]\n"
}

///|
/// Parses command-line arguments, excluding the program name.
pub fn parse_cli_args(args : Array[String]) -> CliOptions raise ExtractionError {
  let mut path = ""
  let mut format = OutputFormat::Json
  let mut base_url : String? = None
  let mut index = 0
  while index < args.length() {
    let arg = args[index]
    if arg == "--json" {
      format = OutputFormat::Json
    } else if arg == "--markdown" {
      format = OutputFormat::Markdown
    } else if arg == "--text" {
      format = OutputFormat::Text
    } else if arg == "--base-url" {
      index += 1
      if index >= args.length() {
        raise Usage("--base-url requires a value")
      }
      base_url = Some(args[index])
    } else if arg.has_prefix("--base-url=") {
      match arg.split_once("=") {
        Some((_, value)) => base_url = Some(value.to_owned())
        None => ()
      }
    } else if arg.has_prefix("-") {
      raise Usage("unknown option: " + arg)
    } else if path == "" {
      path = arg
    } else {
      raise Usage("only one input path is allowed")
    }
    index += 1
  }
  if path == "" {
    raise Usage("missing input path")
  }
  { path, format, base_url, }
}

///|
/// Renders an article in the requested format.
pub fn render_article(
  article : Article,
  format : OutputFormat,
) -> String raise ExtractionError {
  match format {
    Json => article_to_json_string(article)
    Text => article.content_text
    Markdown => article_to_markdown(article)
  }
}

///|
fn extraction_error_message(error : ExtractionError) -> String {
  match error {
    ParseFailed(message) => message
    Usage(message) => message
  }
}

///|
fn extract_with_base(
  html : String,
  base_url : String?,
) -> Article raise ExtractionError {
  match base_url {
    Some(base) =>
      extract_article(html, options=ExtractionOptions::new(base_url=base))
    None => extract_article(html)
  }
}

///|
/// Runs the CLI core with an injected file reader.
pub fn run_cli_args(
  args : Array[String],
  read_file : (String) -> String?,
) -> CliResult {
  if args.length() > 0 && (args[0] == "--help" || args[0] == "-h") {
    return { stdout: cli_help(), stderr: "", exit_code: 0, }
  }
  if args.length() > 0 && args[0] == "--version" {
    return { stdout: version() + "\n", stderr: "", exit_code: 0, }
  }
  let options = parse_cli_args(args) catch {
    error =>
      return {
        stdout: "",
        stderr: extraction_error_message(error) + "\n",
        exit_code: 2,
      }
  }
  let html = match read_file(options.path) {
    Some(value) => value
    None =>
      return {
        stdout: "",
        stderr: "failed to read: " + options.path + "\n",
        exit_code: 1,
      }
  }
  if html == "" {
    return {
      stdout: "",
      stderr: "input is empty: " + options.path + "\n",
      exit_code: 1,
    }
  }
  let article = extract_with_base(html, options.base_url) catch {
    error =>
      return {
        stdout: "",
        stderr: extraction_error_message(error) + "\n",
        exit_code: 1,
      }
  }
  let output = render_article(article, options.format) catch {
    error =>
      return {
        stdout: "",
        stderr: extraction_error_message(error) + "\n",
        exit_code: 1,
      }
  }
  { stdout: output + "\n", stderr: "", exit_code: 0, }
}
