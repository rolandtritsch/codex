# Repository Guidelines

This file captures repository conventions for coding agents and maintainers.
For contributor setup, local testing workflow, and pull request submission, see
`CONTRIBUTING.md`. For user-facing installation and usage, see `README.md`.

## Project Structure & Module Organization

- `codex.el`: main package source, including custom variables, terminal backends, interactive commands, hooks, and minor mode setup.
- `codex-test.el`: ERT test suite for CLI args, hook configuration, terminal behavior, autosuggestions, display remapping, and transcript handling.
- `bin/codex-hook-wrapper`: POSIX shell wrapper used by Codex CLI hooks to call Emacs through `emacsclient`.
- `README.md`, `README.org`, `codex.texi`: user documentation and manual formats.
- `.github/workflows/`: CI configuration for byte compilation and tests.

## Build & Test Commands

- `make test`: run the ERT test suite in batch Emacs.
- `make compile`: byte-compile `codex.el` with warnings treated as errors.
- `make clean`: remove generated `.elc` files.

The Makefile expects dependencies in sibling directories such as `../transient`, `../inheritenv`, `../compat`, `../seq`, and `../cond-let`. CI shows exact versions.

## Coding Style & Naming Conventions

- Keep `lexical-binding: t`.
- Use two-space Lisp indentation as produced by Emacs.
- Public commands and user options use the `codex-` prefix.
- Private helpers and state use `codex--`.
- Tests use `codex-test-` names.
- Prefer the terminal backend dispatch layer before adding backend-specific conditionals.

For shell scripts, keep POSIX `sh` compatibility unless there is a documented reason to require another shell.

## Testing Guidelines

Tests use Emacs ERT and live in `codex-test.el`. Add focused regression tests near related tests. Names should describe behavior, for example `codex-test-build-cli-args-defaults`.
See `CONTRIBUTING.md` for the contributor test workflow and manual verification guidance.

## Commit & Pull Request Notes

Recent commits use short imperative subjects, often with an optional `codex:` scope, for example `Preserve Codex Eat session scrollback` or `codex: retry transient hook dispatch failures`.

Use `CONTRIBUTING.md` for the full PR checklist.

## Security & Configuration Tips

Hook handling may receive sensitive JSON from the Codex CLI. Keep hook payloads out of command-line arguments and preserve the temp-file transport in `bin/codex-hook-wrapper`. Do not overwrite user hook configuration; merge or repair only entries owned by this package.
