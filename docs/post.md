# Writing posts

## Creating a post

Create `_posts/YYYY-MM-DD-title.md` with front matter and Markdown content:

```yaml
---
layout: post
title: "Post title"
category: Tech
tags:
  - Project
description: "Optional summary"
image: /files/MYPROJECT/cover.jpg
toc: true
---
```

`subtitle`, `optimized_image`, and `math` are optional. Cards prefer `optimized_image`; social metadata prefers `image`. Enable `math: true` for MathJax. Enable `toc: true` for the layout's table of contents; do not add a second manual ToC.

Use `Plan` for posts listed on the planning page. The exact tag `Hidden` removes a post from discovery lists while preserving its direct URL. A category does not require a separate category page.

Store images and downloads in `files/` or `assets/`. Use Markdown image syntax for ordinary images; the operating manual documents galleries, local video, Mermaid, and CSV tables/charts.

To split a post into pages, set `paginate: true` in front matter and put `--page-break--` on its own line between sections. This uses `jekyll-paginate-content`, which runs in the current GitHub Actions build.

## Markdown from another repository

Put this on its own line, with blank lines around it, anywhere in the post body:

```liquid
{% remote_markdown "https://raw.githubusercontent.com/OWNER/REPO/main/README.md" %}
```

The tag fetches public GitHub Markdown during the build. Relative links point to the source files on GitHub, and relative images point to raw files. Content is refreshed on the next site build; images remain hosted in the source repository.

See [Including Markdown From Another Repository](../_posts/2003-5-1-Github-Pages-And-Jekyll.md#including-markdown-from-another-repository) for supported paths, version references, and limitations.

## Detailed examples

The [operating manual](../_posts/2003-5-1-Github-Pages-And-Jekyll.md#front-matter-cheatsheet) contains the front matter reference and media examples. Use [local build and preview commands](setup.md#local-commands) to check the post before publishing.
