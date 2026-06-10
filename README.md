# fish-weft

[![CI](https://github.com/abrosimov/fish-weft/actions/workflows/ci.yml/badge.svg)](https://github.com/abrosimov/fish-weft/actions/workflows/ci.yml)

A [Fisher](https://github.com/jorgebucaran/fisher)-installable [fish shell](https://fishshell.com) plugin that bundles the workflow utilities I use every day: a project & git-worktree manager (`proj` / `wt`), a kubectl/helm helper with fuzzy pickers (`k`, `kpf`, `kms`), and an optional Tide prompt segment.

> [!WARNING]
> **Proof of concept.** This is a personal PoC written in fish to validate ergonomics and command shape. The plan is to **rewrite the substantive commands in Go** once the surface stabilises, so the fish entries become thin shims around a single binary. Until then, expect rough edges, breaking changes between tags, and limited testing.

---

## Install

Requires [Fisher](https://github.com/jorgebucaran/fisher) ≥ 4.

```fish
fisher install abrosimov/fish-weft
```

To update:

```fish
fisher update abrosimov/fish-weft
```

To remove:

```fish
fisher remove abrosimov/fish-weft
```

### Runtime dependencies

| Tool | Required for | Notes |
|------|--------------|-------|
| `git` | `proj`, `wt` | Worktree commands need git ≥ 2.5. |
| `kubectl` | `k`, `kpf`, `kms` | Used as the underlying CLI. |
| `fzf` | `k` interactive pickers | Without fzf, only the explicit-name forms work. |
| `gh` (GitHub CLI) | `wt status` | Reads PR state for each worktree. |
| `helm` | `k helm …` | Only for the helm subcommands. |
| `jq` | `k get-secret --decode` | Used to base64-decode secret values. |
| `mongosh` | `kms` | Mongo shell into the registered pod. |
| [`Tide`](https://github.com/IlanCosman/tide) prompt | Custom PWD prompt segment | **Optional.** The plugin auto-registers a `proj_pwd` segment when Tide is present (see [Tide integration](#tide-integration)). |

---

## What's included

| Command | Purpose |
|---------|---------|
| `proj` | Project navigation: clone, create, list, convert layout, install hooks |
| `proj wt` / `wt` | Git worktree manager (sibling-of-`base/` layout) |
| `k` | Opinionated kubectl wrapper with fuzzy pickers and inline previews |
| `kpf` | Port-forward to registered services by `<env> <svc>` name |
| `kms` | One-command `mongosh` into a registered mongo pod |
| `_tide_item_proj_pwd` | Tide prompt segment showing project-aware PWD (optional) |

---

## `proj` — project & worktree manager

`proj` assumes a workspace root in `$AION_AUTOPOIESEON` (e.g. `~/Projects`) containing one subdirectory per project. The recommended layout is:

```
$AION_AUTOPOIESEON/<project>/
├── base/             # the actual git repo (default branch checkout)
├── <branch-1>/       # worktree, sibling of base/
└── <branch-2>/       # worktree, sibling of base/
```

> [!NOTE]
> Set `$AION_AUTOPOIESEON` in your fish config before using `proj`:
>
> ```fish
> set -Ux AION_AUTOPOIESEON ~/Projects
> ```

> [!IMPORTANT]
> **`PROJECTS_DIR` is deprecated.** Earlier versions used `$PROJECTS_DIR`; it is still read as a fallback when `$AION_AUTOPOIESEON` is unset, with a one-time deprecation warning per shell session. Migrate when convenient:
>
> ```fish
> set -Ux AION_AUTOPOIESEON $PROJECTS_DIR
> set -Ue PROJECTS_DIR
> ```
>
> The fallback will be removed in a future release.

### Project lifecycle

| Command | What it does |
|---------|--------------|
| `proj clone <url>` | Clone into `<project>/base/`, install local git hooks, `cd` in. |
| `proj new <name>` | Create empty `<project>/base/` with `git init`. |
| `proj convert <name>` | Migrate an old-style single-tree project to the new `base/` layout, preserving root-level `CLAUDE.md` / `.claude/`. |
| `proj hooks` | Re-install hooks (from `~/.local/share/proj/hooks/`) into the current project. |
| `proj ls` | List every directory under `$AION_AUTOPOIESEON`. |
| `proj <name>` | `cd` into a project (drops you in `base/` if it exists). |

### Worktree commands (also available as `wt …`)

| Command | What it does |
|---------|--------------|
| `proj wt add <branch> [--from <base>]` | Create a worktree at `<project>/<branch>/`. Tracks existing remote branches automatically. |
| `proj wt fork <branch>` | Fork a new worktree from the current HEAD. |
| `proj wt sync` | Detect upstream and merge `origin/<upstream>` into the current worktree. |
| `proj wt push` | `git push -u origin <current-branch>`. |
| `proj wt ls` | List worktrees (delegates to `git worktree list`). |
| `proj wt status` | Per-worktree summary with ahead-of-default count and `gh pr view` state. |
| `proj wt rm [-f] <name>` | Remove the worktree and its branch (`-d` by default; `-f` upgrades to `-D`). |
| `proj wt clean` | Remove every fully-merged worktree. |
| `proj wt <name>` | `cd` into a worktree directory. |

Branch names containing `/` get sanitised in the directory: `feature/login` → `<project>/feature-login/`.

### `.wtfiles` manifest

When `<project>/base/` contains a `.wtfiles` file, `wt add` and `wt fork` seed the new worktree with the gitignored paths it lists. Without a manifest, you'll be prompted interactively for ignored files that look reusable (everything except common build/cache directories).

Verbs:

```
.env                # bare path → symlink (default)
link data/fixtures  # explicit symlink
copy config/local   # copy instead — for entries that must diverge per worktree
```

---

## `k` — kubectl helper

A wrapper around `kubectl` (and `helm`) that adds fuzzy pod resolution and fzf pickers with inline previews. Expects `$KUBECONFIG` to be set by an upstream wrapper.

```fish
set -x KUBECONFIG ~/.kube/staging.yaml
k pods my-namespace             # list pods
k logs my-namespace api -f      # follow logs from a pod whose name contains "api"
k exec my-namespace api -- bash # exec into the first match (fzf if multiple)
k pf svc my-namespace api 8080  # port-forward (auto-assigns local = remote + 10000)
k describe my-namespace deploy  # fzf picker for deploy names
k get-secret my-ns my-secret --decode
k helm values my-ns             # fzf release picker
```

Run `k` with no arguments for the full command reference.

### Fuzzy pod resolution

For commands that take an optional pod filter (`logs`, `exec`, `containers`, `images`, `ports`, `pf pod`, `debug`):

- **No filter** → full fzf picker with `kubectl describe` preview.
- **Filter matches exactly one pod** → resolved silently and used.
- **Filter matches multiple pods** → fzf picker pre-filtered to matches.
- **No matches** → error.

---

## `kpf` — port-forward registry

`kpf` looks up `<env>:<service>` in a user-defined `_kpf_registry` function and forwards the right pod/port via the correct `KUBECONFIG`.

```fish
kpf list                # show all registered combos
kpf staging mongo       # forward localhost:57017 → pod/mongodb-0:27017
kpf staging redis --info  # dry-run: print what would be executed
```

### Registry setup

`fish-weft` does not ship a registry — credentials and namespaces are yours. Create `~/.config/fish/functions/_kpf_registry.fish` with the following shape:

```fish
function _kpf_registry
    if test (count $argv) -eq 0
        # Listing form (used by `kpf list`)
        echo "staging mongo"
        echo "prod    mongo"
        echo "staging redis"
        return 0
    end

    set -l env $argv[1]
    set -l svc $argv[2]

    switch "$env:$svc"
        case "staging:mongo"
            echo "$HOME/.kube/staging.yaml mongodb mongodb-0 57017 27017"
        case "prod:mongo"
            echo "$HOME/.kube/prod.yaml    mongodb mongodb-0 37017 27017"
        case "staging:redis"
            echo "$HOME/.kube/staging.yaml redis   redis-master-0 56379 6379"
        case '*'
            return 1
    end
end
```

The lookup form emits a single space-delimited line: `<kubeconfig> <namespace> <pod> <local-port> <remote-port>`. The same registry powers `kms`, which only reads the first three fields.

---

## `kms` — mongosh shortcut

```fish
kms staging          # opens mongosh on the registered staging mongo pod
kms staging --info   # dry-run
```

Uses the same `_kpf_registry` lookup as `kpf`. The local/remote port fields are ignored.

---

## Tide integration

If you have [Tide](https://github.com/IlanCosman/tide) installed at the moment you run `fisher install` (or `fisher update`) on this plugin, it will automatically register a `proj_pwd` prompt segment that replaces Tide's built-in `pwd` segment with a project-aware variant:

- Inside `$AION_AUTOPOIESEON/<project>/...` → shows `project` (or `project/.../last` for deeper paths).
- Elsewhere → collapses long paths to `first/.../last`.

If you install Tide **after** fish-weft, re-run `fisher update abrosimov/fish-weft` to trigger registration. To opt out at any time, remove `proj_pwd` from `tide_left_prompt_items`:

```fish
set -U tide_left_prompt_items (string match -v proj_pwd $tide_left_prompt_items)
```

Removing `fish-weft` via `fisher remove` restores Tide's default `pwd` segment.

---

## Development

```fish
git clone https://github.com/abrosimov/fish-weft.git
cd fish-weft
fisher install $PWD     # link the local checkout
```

CI runs `fish -n` over every `.fish` file in `functions/`, `completions/`, and `conf.d/` on each push. See [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

---

## License

MIT — see [LICENSE](LICENSE).
