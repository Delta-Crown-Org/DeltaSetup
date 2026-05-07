# Raw findings — GitHub Pages / no-build constraints

Source: GitHub Docs, “What is GitHub Pages?”, https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages

Relevant findings:

- GitHub Pages is a static site hosting service.
- It takes HTML, CSS, and JavaScript files straight from a repository on GitHub.
- It optionally runs files through a build process and publishes a website.
- Project sites are stored in a folder within the repository containing the project code and are hosted at `https://<owner>.github.io/<repositoryname>` by default.
- GitHub notes visitor IP addresses are logged/stored for security purposes.

Implication: DeltaSetup can and should keep the redesign as static HTML/CSS/JS without a build step. Design-system governance has to come from tokens, naming, component discipline, and review—not framework tooling.