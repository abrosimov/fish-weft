# Tests for the Tide prompt-item swap math. The pure helpers take items as
# argv and emit the new list on stdout — no universal-variable side effects.

source functions/_fish_weft_tide_insert_proj_pwd.fish
source functions/_fish_weft_tide_restore_pwd.fish

# --- Insert: replace pwd with proj_pwd ---

@test "insert at middle" (_fish_weft_tide_insert_proj_pwd os pwd git status | string join ' ') = 'os proj_pwd git status'

@test "insert at start" (_fish_weft_tide_insert_proj_pwd pwd git | string join ' ') = 'proj_pwd git'

@test "insert at end" (_fish_weft_tide_insert_proj_pwd os git pwd | string join ' ') = 'os git proj_pwd'

@test "insert when only pwd" (_fish_weft_tide_insert_proj_pwd pwd | string join ' ') = 'proj_pwd'

# --- Insert: no pwd present → append ---

@test "insert appends when pwd absent" (_fish_weft_tide_insert_proj_pwd os git | string join ' ') = 'os git proj_pwd'

# --- Insert: idempotent ---

@test "insert is idempotent" (_fish_weft_tide_insert_proj_pwd os proj_pwd git | string join ' ') = 'os proj_pwd git'

# --- Restore: replace proj_pwd with pwd ---

@test "restore at middle" (_fish_weft_tide_restore_pwd os proj_pwd git status | string join ' ') = 'os pwd git status'

@test "restore at start" (_fish_weft_tide_restore_pwd proj_pwd git | string join ' ') = 'pwd git'

@test "restore at end" (_fish_weft_tide_restore_pwd os git proj_pwd | string join ' ') = 'os git pwd'

@test "restore when only proj_pwd" (_fish_weft_tide_restore_pwd proj_pwd | string join ' ') = 'pwd'

# --- Restore: idempotent when proj_pwd absent ---

@test "restore no-op when proj_pwd absent" (_fish_weft_tide_restore_pwd os git | string join ' ') = 'os git'
