# CLAUDE.md — alaif

This repo is the **brain** for *Alaif* (working title): a Fruit Ninja–style mobile game built around Arabic letters. It follows the LLM Wiki pattern (see `LLM_WIKI.md`): the LLM builds and maintains a persistent, interlinked markdown wiki covering design, architecture, research, and plans. Eventually the app itself will be coded here too.

## Layout

- `CLAUDE.md` — this schema file. Co-evolves with the user.
- `LLM_WIKI.md` — the pattern this repo follows. Read-only reference.
- `raw/` — immutable source documents (notes, articles, transcripts). Never modify.
- `wiki/` — LLM-maintained knowledge base. The LLM owns this layer.
  - `wiki/index.md` — catalog of every wiki page, by category. Update on every ingest.
  - `wiki/log.md` — append-only chronological record. Entry format: `## [YYYY-MM-DD] <op> | <title>` where op ∈ ingest/query/lint/decision.
  - Pages use kebab-case filenames and `[[wikilinks]]` for cross-references (Obsidian-compatible).
- `app/` — the Flutter mobile app (placeholder for now; has its own CLAUDE.md).

## Conventions

- Wiki pages get YAML frontmatter: `title`, `type` (concept | decision | research | spec | plan), `created`, `updated`.
- Decisions are first-class pages: context, options considered, choice, consequences (lightweight ADR).
- Good query answers get filed back into the wiki as pages — explorations compound.
- When new info contradicts an existing page, update the page and note the supersession in `log.md`.

## Workflows

- **Ingest**: read source in `raw/`, discuss takeaways, write/update wiki pages, update index, append to log.
- **Query**: read `wiki/index.md` first, drill into relevant pages, cite them; file valuable answers back.
- **Lint**: on request, check for contradictions, orphans, stale claims, missing pages.

## Project context

- Solo dev: strong full-stack/enterprise + Flutter background; new to game dev.
- Target stack: Flutter (Android + iOS). Backend, if ever needed, is Firebase — but the strong preference is **no backend** (offline-first).
- Status: brainstorming/design phase. No app code yet.
