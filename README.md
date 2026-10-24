# moon-readability

A pure-MoonBit library for extracting the main article content from HTML pages.

## Status

Early development. The public API is not stable yet.

## Goals

- Extract the title, byline, site name, published time, and main content.
- Remove navigation, ads, footers, and comment sections.
- Output clean HTML, plain text, and Markdown.

## Non-goals

- Executing JavaScript or rendering a browser page.
- Fetching URLs or handling authenticated sessions.
- Full Readability.js API compatibility.

## Build

```bash
moon check
moon build
moon test
```

## License

Apache-2.0.
