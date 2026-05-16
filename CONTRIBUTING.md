# Contributing

This project is an Emacs package for the Codex CLI. If you are looking for
installation, configuration, or day-to-day usage, start with [README.md][readme].
For repository layout, naming conventions, and maintainer-oriented notes, see
[AGENTS.md][agents].

## Development Setup

1. Fork the repository on GitHub and clone your fork.
2. Create a topic branch:

   ```sh
   git switch -c my-change
   ```

3. Make sure Emacs 28.1 or later is available as `emacs`, or set `EMACS` when
   running make targets.
4. Install or check out the test dependencies next to this repository. The
   default `Makefile` looks for sibling directories named `transient`,
   `inheritenv`, `compat`, `seq`, and `cond-let`. Override `DEPS_DIR` or
   `LOAD_PATH_EXTRA` if your checkout layout is different.

## Making Changes

Keep changes focused on one behavior or documentation update at a time. For
public commands, user options, hooks, terminal behavior, or CLI arguments, update
the relevant tests in `codex-test.el`. For user-facing behavior, update the
appropriate documentation rather than relying on commit messages or PR text.

When changing terminal or hook behavior, manually exercise the affected workflow
in Emacs if possible. In particular, check behavior around missing buffers,
stale hook entries, backend-specific terminal paths, and existing user hook
configuration.

## Testing

Run the full local checks before opening a pull request:

```sh
make compile
make test
```

Use `make compile` to byte-compile `codex.el` with warnings treated as errors.
Use `make test` to run the ERT suite in batch Emacs.

For documentation-only changes, the full test suite is usually optional, but
still check the rendered Markdown and any links you touched.

## Submitting a Pull Request

1. Review your changes locally:

   ```sh
   git status --short
   git diff
   ```

2. Commit with a short imperative subject, for example:

   ```sh
   git commit -m "codex: describe the changed behavior"
   ```

3. Push your branch to your fork:

   ```sh
   git push -u origin my-change
   ```

4. Open a pull request against the main repository.

In the PR description, include the behavior change, tests run, documentation
updates, and any manual terminal UI verification that applies. If tests are not
applicable, state why.

[agents]: AGENTS.md
[readme]: README.md
