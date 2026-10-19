# Setup and deployment

## Environment

Use Ruby **3.2.11**, as specified in `.ruby-version` and `Gemfile`, and Bundler **2.4.19**, as recorded in `Gemfile.lock`. Node.js is also needed for Gulp; `package.json` declares Node >=16.

Use the repository's locked dependencies; global Jekyll and Gulp installations are unnecessary. Before installing or changing npm dependencies, run `npm audit` against the lockfile and resolve reported vulnerabilities. Pin any added package to an exact audited version.

```sh
bundle install
npm audit
npm ci
```

If Ruby is managed through mise, prefix Ruby commands with `mise exec ruby --`. The Gulp build detects mise automatically when available.

## Local commands

```sh
npm run dev            # Build, serve with BrowserSync, and watch local source files
npm run build          # Generate config/theme/JS, then build Jekyll
npm run preview        # Serve the existing _site at http://127.0.0.1:4000
npm run preview:build  # Build, then start that preview server
```

BrowserSync prints its development URL when it starts. The separate preview server uses port 4000 by default; set `PORT` to change it. Preview alone does not rebuild files.

Edit configuration in `src/yml/`; see [Settings](settings.md). Put published media in `files/` or `assets/`. The current build does not process `src/img/`.

## Validation

```sh
bundle exec ruby _tests/remote_markdown_test.rb
npm run build
```

The remote Markdown tests use simulated HTTP responses and temporary Jekyll sites. They need no network access. Actual posts containing `remote_markdown` require access to GitHub during the build.

## GitHub Pages deployment

`.github/workflows/pages.yml` builds and deploys on pushes to `master`, or when manually run through GitHub Actions. Feature branches do not deploy automatically.

The workflow runs `bundle exec jekyll build` directly and uploads `_site`. It does **not** run Gulp. After changing configuration, theme values, or JavaScript sources, run `npm run build` locally and include the relevant generated `_config.yml`, `_sass/_theme.scss`, and `assets/js/` changes in the commit.

Custom plugins in `_plugins/` run during this Actions build. No Netlify deployment is needed. Changes in a repository referenced by `remote_markdown` appear on the next site build; there is no cross-repository update trigger.
