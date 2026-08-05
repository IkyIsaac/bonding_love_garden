# Bonding Love Garden — Documentation Site

Developer Guide + User Guide for the play park management platform, built with [Docusaurus](https://docusaurus.io/). Content lives under `docs/developer-guide/` and `docs/user-guide/`, filled in incrementally as features ship (see `PROGRESS.md` at the repo root).

## Local development

```bash
npm install
npm start
```

Starts a dev server with live reload at `http://localhost:3000`.

## Build

```bash
npm run build
```

Generates static output into `build/`, deployable to any static host. Not deployed anywhere yet — `docusaurus.config.ts`'s `url` is a placeholder until a real docs host is chosen.
