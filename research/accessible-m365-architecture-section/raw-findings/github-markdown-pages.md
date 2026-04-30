# Raw findings: GitHub Markdown and Pages

## Basic writing and formatting syntax

Source: https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax

Extracted findings:

- GitHub Markdown supports headings from `#` to `######`; two or more headings produce an outline menu in rendered files.
- GitHub supports section links and generated anchors from headings.
- Relative links and image paths are recommended for repository files because absolute links may not work in clones.
- Images use `![alt text](path)`; alt text is described by GitHub as a short text equivalent of the image information.
- GitHub alerts should be used only when crucial for user success and limited to one or two per article to avoid overload.
- GitHub supports the `<picture>` element in Markdown.

## Creating diagrams

Source: https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams

Extracted findings:

- GitHub supports diagrams in Markdown using Mermaid, GeoJSON, TopoJSON, and ASCII STL.
- Diagram rendering is available in GitHub Issues, Discussions, pull requests, wikis, and Markdown files.
- Mermaid diagrams are created in fenced code blocks with the `mermaid` language identifier.
- GitHub recommends checking GitHub’s currently supported Mermaid version with a Mermaid `info` diagram.

## GitHub Pages

Source: https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages

Extracted findings:

- GitHub Pages is a static site hosting service that publishes HTML, CSS, and JavaScript files from a repository, optionally through a build process.
- Project sites are stored in a folder within the repository and publish under `https://<owner>.github.io/<repositoryname>` by default.
- GitHub Pages logs visitor IP addresses for security purposes regardless of sign-in state.
