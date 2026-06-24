# Tests for `branch.<name>.wt-parent` stamping (proj wt add / proj wt fork)
# and the wt-parent → @{upstream} → whitelist priority used by proj wt sync.
# Builds throwaway projects under mktemp; never touches the user's $HOME.

source functions/__fish_weft_workspace_root.fish
source functions/proj.fish

set -l tmpdir_root $TMPDIR
test -z "$tmpdir_root"; and set tmpdir_root /tmp
set -l tmp (mktemp -d "$tmpdir_root/wf-wtparent.XXXXXX")

set -gx AION_AUTOPOIESEON $tmp
set -e PROJECTS_DIR

# Defensive git config so commits succeed under CI / unconfigured shells.
function _wf_gitprep --argument-names dir
    git -C $dir config commit.gpgsign false
    git -C $dir config user.email test@example.com
    git -C $dir config user.name "fish-weft tests"
end

set -l saved_pwd $PWD

# --- __proj_wt_stamp_parent unit tests ---

mkdir -p $tmp/stamphelper
git -C $tmp/stamphelper init -q -b main
_wf_gitprep $tmp/stamphelper

__proj_wt_stamp_parent $tmp/stamphelper main feature-x >/dev/null
@test "stamp_parent writes branch.<name>.wt-parent" (git -C $tmp/stamphelper config --get branch.main.wt-parent) = feature-x

__proj_wt_stamp_parent $tmp/stamphelper main "" >/dev/null
@test "stamp_parent with empty parent is a no-op" (git -C $tmp/stamphelper config --get branch.main.wt-parent) = feature-x

__proj_wt_stamp_parent $tmp/stamphelper main HEAD >/dev/null
@test "stamp_parent with HEAD parent is a no-op (detached source)" (git -C $tmp/stamphelper config --get branch.main.wt-parent) = feature-x

# --- proj wt add: new branch from a non-default base ---

mkdir -p $tmp/proj-add-new/base
git -C $tmp/proj-add-new/base init -q -b main
_wf_gitprep $tmp/proj-add-new/base
echo seed >$tmp/proj-add-new/base/file
git -C $tmp/proj-add-new/base add file
git -C $tmp/proj-add-new/base commit -qm "init"
git -C $tmp/proj-add-new/base checkout -qb feature-parent
git -C $tmp/proj-add-new/base commit --allow-empty -qm "parent work"

cd $tmp/proj-add-new/base
proj wt add my-feature >/dev/null 2>&1
cd $saved_pwd
@test "wt add stamps base_branch when creating a new branch" (git -C $tmp/proj-add-new/my-feature config --get branch.my-feature.wt-parent) = feature-parent

# --- proj wt add: existing local branch without @{upstream} ---

mkdir -p $tmp/proj-add-local/base
git -C $tmp/proj-add-local/base init -q -b main
_wf_gitprep $tmp/proj-add-local/base
echo seed >$tmp/proj-add-local/base/file
git -C $tmp/proj-add-local/base add file
git -C $tmp/proj-add-local/base commit -qm "init"
# Branch exists locally with no tracking; base/ is on main when we add it.
git -C $tmp/proj-add-local/base branch lone-branch

cd $tmp/proj-add-local/base
proj wt add lone-branch >/dev/null 2>&1
cd $saved_pwd
@test "wt add stamps base_branch when local branch exists without upstream" (git -C $tmp/proj-add-local/lone-branch config --get branch.lone-branch.wt-parent) = main

# --- proj wt fork: stamps the source branch ---

mkdir -p $tmp/proj-fork/base
git -C $tmp/proj-fork/base init -q -b main
_wf_gitprep $tmp/proj-fork/base
echo seed >$tmp/proj-fork/base/file
git -C $tmp/proj-fork/base add file
git -C $tmp/proj-fork/base commit -qm "init"

cd $tmp/proj-fork/base
proj wt add base-feature >/dev/null 2>&1
cd $tmp/proj-fork/base-feature
proj wt fork sub-feature >/dev/null 2>&1
cd $saved_pwd
@test "wt fork stamps source branch as parent" (git -C $tmp/proj-fork/sub-feature config --get branch.sub-feature.wt-parent) = base-feature

# --- proj wt sync: wt-parent priority + local merge when no origin/<parent> ---

mkdir -p $tmp/proj-sync/base
git -C $tmp/proj-sync/base init -q -b main
_wf_gitprep $tmp/proj-sync/base
echo seed >$tmp/proj-sync/base/file
git -C $tmp/proj-sync/base add file
git -C $tmp/proj-sync/base commit -qm "init"
git -C $tmp/proj-sync/base checkout -qb feature-parent
git -C $tmp/proj-sync/base commit --allow-empty -qm "parent work"

cd $tmp/proj-sync/base
proj wt add my-feature >/dev/null 2>&1
# Advance parent so sync has work to merge.
git -C $tmp/proj-sync/base commit --allow-empty -qm "parent advance"
cd $tmp/proj-sync/my-feature
set -l sync_output (proj wt sync 2>&1)
cd $saved_pwd

@test "wt sync uses wt-parent" (string match -q '*via wt-parent*' -- $sync_output; echo $status) -eq 0
@test "wt sync merges local ref when no origin/<parent>" (string match -q '*local, via wt-parent*' -- $sync_output; echo $status) -eq 0

# --- Cleanup ---

cd /
test -n "$tmp"; and test -d "$tmp"; and rm -rf $tmp
