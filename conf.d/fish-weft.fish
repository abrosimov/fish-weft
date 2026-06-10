# fish-weft — Fisher install/update/uninstall hooks.
#
# Tide is an OPTIONAL dependency. When Tide is present at install/update time,
# we replace the default `pwd` item in `tide_left_prompt_items` with our
# project-aware `proj_pwd`. When Tide is absent, the plugin still works — only
# `_tide_item_proj_pwd` is unused and never autoloaded.
#
# Swap math is delegated to autoload helpers in functions/ so it stays
# unit-testable without touching universal variables.

function _fish_weft_apply_tide_swap
    set -q tide_left_prompt_items; or return 0
    contains proj_pwd $tide_left_prompt_items; and return 0
    set -U tide_left_prompt_items (_fish_weft_tide_insert_proj_pwd $tide_left_prompt_items)
end

function _fish_weft_revert_tide_swap
    set -q tide_left_prompt_items; or return 0
    contains proj_pwd $tide_left_prompt_items; or return 0
    set -U tide_left_prompt_items (_fish_weft_tide_restore_pwd $tide_left_prompt_items)
end

function _fish_weft_install --on-event fish_weft_install
    _fish_weft_apply_tide_swap
end

function _fish_weft_update --on-event fish_weft_update
    _fish_weft_apply_tide_swap
end

function _fish_weft_uninstall --on-event fish_weft_uninstall
    _fish_weft_revert_tide_swap
end
