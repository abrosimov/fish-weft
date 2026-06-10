# Tests for the __proj_* autoload helpers used by completions and proj wt
# command resolution. We build a throwaway workspace under mktemp and point
# AION_AUTOPOIESEON at it.

source functions/__fish_weft_workspace_root.fish
source functions/__proj_current_project.fish
source functions/__proj_base_dir.fish
source functions/__proj_worktree_names.fish

set -l tmpdir_root $TMPDIR
test -z "$tmpdir_root"; and set tmpdir_root /tmp
set -l tmp (mktemp -d "$tmpdir_root/fish-weft-test.XXXXXX")
mkdir -p $tmp/projA/base $tmp/projA/feature-x $tmp/projA/feature-y
mkdir -p $tmp/projB/base

set -gx AION_AUTOPOIESEON $tmp
set -e PROJECTS_DIR

# --- __proj_current_project ---

cd $tmp/projA/base
@test "current_project from base/" (__proj_current_project) = projA

cd $tmp/projA/feature-x
@test "current_project from worktree" (__proj_current_project) = projA

cd $tmp/projB/base
@test "current_project resolves different project" (__proj_current_project) = projB

cd /tmp
__proj_current_project >/dev/null 2>/dev/null
@test "current_project returns nonzero outside workspace" $status -ne 0

# --- __proj_base_dir ---

cd $tmp/projA/feature-x
@test "base_dir from worktree resolves to project's base/" (__proj_base_dir) = $tmp/projA/base

cd /tmp
__proj_base_dir >/dev/null 2>/dev/null
@test "base_dir returns nonzero outside workspace" $status -ne 0

# --- __proj_worktree_names ---

cd $tmp/projA/base
@test "worktree_names lists siblings excluding base" (__proj_worktree_names | sort | string join ' ') = 'feature-x feature-y'

cd $tmp/projB/base
@test "worktree_names is empty when no worktrees" (__proj_worktree_names | count) -eq 0

# --- Cleanup ---

cd /
test -n "$tmp"; and test -d "$tmp"; and rm -rf $tmp
