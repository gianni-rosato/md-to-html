# Markdown to HTML Converter in Zig

This is a fast & light Markdown to HTML converter written in Zig. It transforms Markdown files into HTML documents, supporting a wide range of Markdown features & custom frontmatter.

## Features

- Converts Markdown to HTML with support for:
  - Headings (H1 to H4)
  - Bold & italicized text
  - Unordered lists
  - Code blocks with language-specific syntax highlighting
  - Links
  - Images
  - Inline code
- Custom frontmatter support for page metadata
- Colorful console output

## Installation

0. Ensure you have Zig installed on your system. If not, download it from [the official Zig website](https://ziglang.org/download/) or use your package manager. The minimum required version is `0.13.0`.

1. Clone this repository:
   ```bash
   git clone https://github.com/gianni-rosato/md-to-html.git
   cd md-to-html
   ```

2. Build the project:
   ```bash
   zig build -Doptimize=ReleaseSafe
   ```

The resulting binary will be located in the `zig-out/bin/` directory.

## Usage

```md
% ./md-to-html -h
Markdown to HTML Converter in **Zig**
Example usage: md-to-html [input.md] [output.html]
Markdown features supported:
    - Headers
    - Headings (H1 to H4)
    - Bold & italicized text
    - Unordered lists
    - Code blocks with language-specific syntax highlighting
    - Links
    - Images
    - Inline code
```

## Custom Frontmatter

This converter supports custom frontmatter for adding metadata to your HTML output. Add the following to the top of your Markdown file:

```yaml
---
name: "Your Page Title"
stylesheet: "path/to/your/stylesheet1.css"
stylesheet: "path/to/your/stylesheet2.css"
---
```

- `name`: Sets the HTML page title
- `stylesheet`: Links an external CSS file to your HTML. You can have multiple stylesheet fields.

The frontmatter should be enclosed between `---` lines at the very beginning of the Markdown file.

## Markdown Support

This converter supports the following Markdown syntax:

- Headings: Use `#` for H1, `##` for H2, and so on up to H4
- Bold: Wrap text with double asterisks `**like this**`
- Italic: Wrap text with single asterisks `*like this*`
- Unordered Lists: Start lines with `-`
- Code Blocks: Use triple backticks ``` with optional language specifier
- Inline Code: Wrap code with single backticks `like this`
- Links: `[Link Text](https://example.com)`
- Images: `![Alt Text](path/to/image.jpg)`

## Example

You can run the binary on the provided Markdown files in the `examples/` directory in order to test its functionality:

```bash
./md-to-html examples/input.md examples/output.html
```

```bash
./md-to-html examples/qoi.md examples/qoi.html
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the [Apache 2.0 License](LICENSE).
