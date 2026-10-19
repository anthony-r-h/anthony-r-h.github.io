# Legacy Netlify CMS files

`admin/` contains inherited Netlify CMS configuration using Git Gateway and an editorial workflow. Its schema still references template features such as authors and category layouts that are not part of the current site layouts.

This repository's deployment is GitHub Actions → GitHub Pages, as defined in `.github/workflows/pages.yml`. The presence of `admin/` does not establish that Netlify Identity or Git Gateway is configured, and the admin configuration has not been validated against an external service.

Use the [current setup and deployment instructions](setup.md) and edit posts in `_posts/`. The legacy admin files remain in the repository; bringing that editor back into use would require a separate configuration review.
