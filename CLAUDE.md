# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Academic study material for **72.07 - Protocolos de Comunicación** at ITBA. Contains class notes, theory PDFs, and practice exercises for a networking/protocols course covering HTTP, DNS, mail, transport, routing, SSH, and sockets.

## Structure

- `notas/` — Class notes in Obsidian Markdown (numbered by topic: `0_Network.md` → `10_sockets.md`)
- `teoria/` — PDF slides from lectures (read-only reference material)
- `practica/` — Guided practice exercises, solutions, and lab notes
- `examenes/` — Exam material

## Note Format

All notes use **Obsidian-flavored Markdown** with YAML frontmatter:

```yaml
---
materia: protos
tipo: apuntes
---
```

Practice files use extended frontmatter (`title`, `tags`, `date`, `author`).

Notes use Obsidian callout syntax (`> [!IMPORTANT]`, `> [!NOTE]`, etc.), LaTeX math (`$...$`, `$$...$$`), and image embeds (`![](attachments/...)`).

## Conventions

- Topic numbering in `notas/` matches lecture order; use the existing scheme when adding new notes.
- Spanish is the primary language for prose; technical terms and commands remain in English.
- When editing `practica/Ejercicio_integrador.md`, keep CLI flags in canonical order: flags before the URL (e.g., `-X POST` before the URL, not after).
