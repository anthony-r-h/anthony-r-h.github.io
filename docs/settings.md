# Settings

Edit the source files in `src/yml/`, then run `npm run build`. Root `_config.yml` is generated; do not edit it directly.

| Source | Controls |
| --- | --- |
| `src/yml/site.yml` | Site identity, menu, contact email, footer, home feed filtering/grid, list view defaults |
| `src/yml/posts.yml` | Post layout, typography, spacing, table of contents, CSV table/chart defaults |
| `src/yml/social.yml` | Social usernames |
| `src/yml/theme.yml` | Theme colors used to generate `_sass/_theme.scss` |
| `src/yml/advanced.yml` | Production URL, base path, language |
| `src/yml/_config.yml` | Source includes, Markdown engine, plugins, permalinks, pagination, exclusions |

## Common changes

- Navigation: edit `menu` in `site.yml`.
- Contact address: edit `email` in `site.yml`; the contact layout renders an obfuscated mail link.
- Home visibility: use `home_listing.include_tags` and `home_listing.exclude_tags`. The home feed currently excludes `Plan`.
- Home spacing: edit `home_grid` in `site.yml`.
- Planning/list pages: edit `list_view_ui`, or use per-page `list_*` front matter overrides.
- Post appearance: edit `post_ui` in `posts.yml`, or use per-post `post_*` overrides.
- Theme palette: edit `themeColor`, `primaryDark`, `accentDark`, `lightGray`, `texts`, and `contentBg` in `theme.yml`.
- Hosting path: set `baseurl` in `advanced.yml` (currently empty for a root-domain site).

The [operating manual](../_posts/2003-5-1-Github-Pages-And-Jekyll.md#key-settings-you-will-actually-use) lists front matter overrides and examples. Check the source YAML for current defaults.

GitHub Actions uses the generated files committed to the repository. See [deployment](setup.md#github-pages-deployment) before publishing source configuration changes.
