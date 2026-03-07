<!-- Copilot instructions for contributors and AI agents -->
# Copilot / AI Agent Instructions

Short, actionable notes to be immediately productive in this repository.

- **Big picture:** This repo is a Jekyll-based static site using the "jekflix-template" theme. HTML is authored in `_layouts`, `_includes`, and `_posts`. A Node/Gulp pipeline compiles theme variables, JS and images into `assets/` and then triggers `bundle exec jekyll build` to produce the final `_site` output.

- **Key build / dev commands (exact):**
  - Install Ruby gems: `bundle install` (uses the `Gemfile`)
  - Install Node tooling: `npm ci` or `npm install`
  - Start live dev: `npx gulp` (runs default `run` task which builds assets, runs Jekyll, starts BrowserSync, and watches)
  - One-shot build (production): `npx gulp build` (compiles assets + runs `bundle exec jekyll build`)
  - If you need only Jekyll: `bundle exec jekyll build` or `bundle exec jekyll serve`

- **Windows note:** The gulpfile auto-detects Windows and invokes `bundle.bat` when needed, so run the same `npx gulp` flow on Windows.

- **Where to look first (examples):**
  - build pipeline: [gulpfile.js](gulpfile.js#L1)
  - main site config template: [src/yml/_config.yml](src/yml/_config.yml#L1) (used to generate root `_config.yml` via the `config` gulp task)
  - theme color pipeline: `src/yml/theme.yml` -> `src/tmp/theme.json` -> `_sass/_theme.scss` (see `yamlTheme`/`jsonTheme` tasks in `gulpfile.js`)
  - JS sources: `src/js/main/` (minified/concatenated into `assets/js/scripts.min.js`), `src/js/preview/` (copied to `assets/js/`)
  - images: `src/img/` -> `assets/img/` (optimized by `gulp-imagemin` task)
  - templates/components: `_includes/`, `_layouts/`

- **Conventions & patterns to follow (explicit):**
  - Content posts follow Jekyll naming: `_posts/YYYY-MM-DD-title.md` (see many examples in `_posts/`).
  - Do NOT edit `_site/` — it is generated output.
  - To add a new JS module: place it under `src/js/main/`. The gulp `mainJs` task minifies and concatenates into `assets/js/scripts.min.js`.
  - For preview scripts (e.g., demo-only JS), place files under `src/js/preview/` — they are copied verbatim into `assets/js/`.
  - To change theme tokens (colors, etc.) edit `src/yml/theme.yml` and let the `theme` gulp tasks regenerate `_sass/_theme.scss`.
  - Site-level YAML is composed from `src/yml/_config.yml` via the `config` task; changes there are propagated into the site `_config.yml` before Jekyll runs.

- **Integration points and external services:**
  - Contact form: configured to use Formspree (see `_config.yml` `formspree_form_id`).
  - Comments: optional Disqus via `_config.yml` `disqus_username`.
  - Search index: `search.json` is generated from site posts (inspect `search.html`/plugins if altering indexing).

- **What to change where (quick examples):**
  - Add a new include: put a partial into `_includes/` and reference it from layouts or posts using `{% include my-partial.html %}`.
  - Add a new page layout: create file in `_layouts/` and reference `layout: mylayout` in front-matter.

- **Files to check when debugging builds:**
  - `gulpfile.js` — task orchestration and file watchers
  - `_config.yml` and `src/yml/_config.yml` — final Jekyll config comes from these
  - `_site/` — local generated output (do not commit changes here)

- **Restrictions / gotchas discovered from repo:**
  - `package.json` contains only devDependencies and no build scripts — use `npx gulp` rather than `npm run`.
  - Many images and large files exist under `files/` and `_site/`. Be careful when searching the repo for text — ignore `_site/` and `files/` unless intentionally inspecting generated or uploaded assets.

- If anything above is unclear or you want the instructions to include more examples (e.g., a minimal PR flow, or explicit sample edits for a specific page), tell me which area to expand.
