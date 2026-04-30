# Raw findings: accessibility tool versions

Checked via npm registry on 2026-04-30:

```bash
npm view axe-core version
# 4.11.4

npm view pa11y version
# 9.1.1

npm view lighthouse version
# 13.1.0
```

axe-core release validation:

Source: https://github.com/dequelabs/axe-core/releases

- Latest visible release: 4.11.4.
- Release date visible on GitHub: 2026-04-28.
- Release notes state this patch addresses ancestry selector issues and is unlikely to change the number of issues found by axe-core.
- Recent 4.11.x patch notes include false-positive and target-size behavior changes, which means teams should pin versions for repeatable CI results and review expected deltas after upgrades.
