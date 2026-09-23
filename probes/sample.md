# MarkdownPreview sample

Quick check of **GitHub-flavoured** Markdown: *emphasis*, ~~strikethrough~~, `inline code`, and an autolink https://github.com.

## Table

| Renderer            | Tables | Browser needed | Verdict   |
|:--------------------|:------:|:--------------:|----------:|
| glow                | text   | no             | rejected  |
| pandoc + Chromium   | yes    | yes            | rejected  |
| MarkdownPreview.app | yes    | no             | **used**  |

## Code

```swift
struct Greeting {
    let name: String
    func render() -> String { "Hello, \(name)!" }  // highlighted
}
```

```python
def fib(n: int) -> int:
    return n if n < 2 else fib(n - 1) + fib(n - 2)
```

## Tasks

- [x] tables with borders
- [x] syntax highlighting
- [ ] world domination

## Image relative to the file

![gradient](images/gradient.png)

> Blockquote: links open in the default browser only when clicked — [example.com](https://example.com), [jump to Table](#table), [other file](other.md).
