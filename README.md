# moon-readability

A pure-MoonBit library for extracting the main article content from HTML pages.

`moon-readability` turns a full HTML document into a structured article: title,
byline, site name, publication time, canonical URL, cleaned content HTML, plain
text, a short excerpt, and Markdown. Navigation, sidebars, footers, forms,
scripts, and other boilerplate are removed.

## Features

- Metadata extraction from Open Graph, Twitter cards, standard meta tags,
  `<title>`, `<h1>`, and the document language.
- Content-node scoring using text length, link density, tag names, and
  class/id hints.
- Sibling merging so articles split across several blocks stay together.
- Cleaning of scripts, styles, frames, forms, navigation, sidebars, and
  footers.
- Removal of event-handler attributes, inline styles, and unsafe URL schemes.
- Relative link and image resolution against a base URL, including `srcset`.
- Plain text with block separators, sentence-aware excerpts, and Markdown
  rendering.
- A JSON representation and a small file-based CLI.
- Runs on native, JavaScript, and WebAssembly targets.

## Non-goals

- Executing JavaScript or rendering a browser page.
- Fetching URLs or handling authenticated sessions.
- Full API or output compatibility with Mozilla Readability.
- Acting as a general-purpose HTML sanitizer. `content_html` is filtered for
  common unsafe constructs, but untrusted output should still be handled with
  care.

## Install

```bash
moon add CJ3335556/moon-readability
```

Add the package to your `moon.pkg`:

```text
import {
  "CJ3335556/moon-readability" @readability,
}
```

## Library usage

```moonbit
///|
fn extract(html : String) -> Unit raise {
  let article = @readability.extract_article(html)
  println(article.title)
  println(article.content_text)
  let markdown = @readability.article_to_markdown(article)
  println(markdown)
}
```

Pass a base URL when the document contains relative links or images:

```moonbit
let article = @readability.extract_article(
  html,
  options=@readability.ExtractionOptions::new(
    base_url="https://example.com/posts/1",
  ),
)
```

Other public helpers:

- `extract_metadata(html, base_url?)` — metadata only.
- `article_to_json_string(article)` — stable JSON representation.
- `article_to_markdown(article)` — Markdown rendering.
- `version()` — library version.

## CLI

```bash
# JSON (default)
moon run cmd/main -- testdata/basic.html --json

# Markdown
moon run cmd/main -- testdata/blog.html --markdown

# Plain text
moon run cmd/main -- testdata/chinese.html --text

# Resolve relative URLs against a base
moon run cmd/main -- testdata/open_graph.html --json \
  --base-url https://example.com/posts/1
```

The CLI reads a local HTML file. Use `--help` for usage and `--version` for the
current version.

## Example

A self-contained example is available in `examples/`:

```bash
moon run examples
```

It extracts an inline HTML document and prints the title, text, and Markdown.

## Project layout

```text
.
├── article.mbt          public article and metadata types
├── metadata.mbt         metadata extraction and article assembly
├── score.mbt            content scoring, selection, sibling merging
├── url.mbt              relative URL resolution
├── text.mbt             text normalization and excerpts
├── markdown.mbt         Markdown rendering
├── json.mbt             JSON output
├── cli.mbt              testable CLI core
├── cmd/main/            executable entry point
├── internal/html/       HTML parser adapter
├── examples/            runnable example
└── testdata/            local HTML fixtures
```

The parser dependency is isolated in `internal/html/`; public APIs do not
expose parser types.

## Development

```bash
moon check
moon build
moon test
moon fmt --check
```

The test suite covers metadata, scoring, selection, sibling merging, cleaning,
URL resolution, text and excerpts, Markdown, JSON, the CLI core, local HTML
fixtures, malformed markup, and long documents.

## License

Apache-2.0. See `LICENSE` and `NOTICE`.

The extraction approach is inspired by Mozilla Readability. HTML parsing is
provided by `bobzhang/html_parser`. The test fixtures in `testdata/` were
written for this project.
