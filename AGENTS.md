# Repository Guidelines

## Project Structure & Module Organization

- `codex.el`: main package source, including custom variables, terminal backends, interactive commands, hooks, and minor mode setup.
- `codex-test.el`: ERT test suite for CLI args, hook configuration, terminal behavior, autosuggestions, display remapping, and transcript handling.
- `bin/codex-hook-wrapper`: POSIX shell wrapper used by Codex CLI hooks to call Emacs through `emacsclient`.
- `README.md`, `README.org`, `codex.texi`: user documentation and manual formats.
- `.github/workflows/`: CI configuration for byte compilation and tests.

## Build, Test, and Development Commands

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

Before submitting changes, run:

```sh
make compile
make test
```

For terminal or hook changes, cover edge cases such as missing buffers, stale hook entries, or backend-specific paths.

## Commit & Pull Request Guidelines

Recent commits use short imperative subjects, often with an optional `codex:` scope, for example `Preserve Codex Eat session scrollback` or `codex: retry transient hook dispatch failures`.

Pull requests should include:

- A concise description of the behavior change.
- Tests added or updated, or a clear reason tests are not applicable.
- Any user-facing configuration or documentation changes.
- Manual verification notes for terminal UI behavior when relevant.

## Security & Configuration Tips

Hook handling may receive sensitive JSON from the Codex CLI. Keep hook payloads out of command-line arguments and preserve the temp-file transport in `bin/codex-hook-wrapper`. Do not overwrite user hook configuration; merge or repair only entries owned by this package.
