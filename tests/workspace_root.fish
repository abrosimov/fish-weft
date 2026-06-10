# Tests for __fish_weft_workspace_root: resolution precedence and deprecation.

source functions/__fish_weft_workspace_root.fish

function _reset_workspace_env
    set -e AION_AUTOPOIESEON
    set -e PROJECTS_DIR
    set -e __fish_weft_projects_dir_warned
end

# --- AION_AUTOPOIESEON primary ---

_reset_workspace_env
set -gx AION_AUTOPOIESEON /tmp/wf-aion
@test "uses AION_AUTOPOIESEON when set" (__fish_weft_workspace_root) = /tmp/wf-aion
@test "no stderr when AION_AUTOPOIESEON set" (__fish_weft_workspace_root 2>&1 >/dev/null | count) -eq 0

# --- PROJECTS_DIR fallback ---

_reset_workspace_env
set -gx PROJECTS_DIR /tmp/wf-legacy
@test "falls back to PROJECTS_DIR when AION_AUTOPOIESEON unset" (__fish_weft_workspace_root 2>/dev/null) = /tmp/wf-legacy

# --- Deprecation warning fires on first PROJECTS_DIR fallback ---

_reset_workspace_env
set -gx PROJECTS_DIR /tmp/wf-legacy
set -l warning_lines (__fish_weft_workspace_root 2>&1 >/dev/null)
@test "deprecation warning prints 2 stderr lines on first call" (count $warning_lines) -eq 2
@test "deprecation warning mentions 'deprecated'" (string match -q '*deprecated*' -- $warning_lines; echo $status) -eq 0
@test "deprecation warning mentions AION_AUTOPOIESEON" (string match -q '*AION_AUTOPOIESEON*' -- $warning_lines; echo $status) -eq 0

# --- Warning fires only once per shell session ---

_reset_workspace_env
set -gx PROJECTS_DIR /tmp/wf-legacy
__fish_weft_workspace_root >/dev/null 2>/dev/null
set -l silent_lines (__fish_weft_workspace_root 2>&1 >/dev/null | count)
@test "deprecation warning silent on subsequent calls" $silent_lines -eq 0

# --- AION wins when both set, no warning ---

_reset_workspace_env
set -gx AION_AUTOPOIESEON /tmp/wf-aion
set -gx PROJECTS_DIR /tmp/wf-legacy
@test "AION_AUTOPOIESEON wins when both set" (__fish_weft_workspace_root) = /tmp/wf-aion
@test "no warning when both set" (__fish_weft_workspace_root 2>&1 >/dev/null | count) -eq 0

# --- Neither set → nonzero, no stdout ---

_reset_workspace_env
__fish_weft_workspace_root >/dev/null 2>/dev/null
@test "returns nonzero when neither variable set" $status -ne 0

_reset_workspace_env
set -l output (__fish_weft_workspace_root 2>/dev/null | count)
@test "no stdout when neither variable set" $output -eq 0
