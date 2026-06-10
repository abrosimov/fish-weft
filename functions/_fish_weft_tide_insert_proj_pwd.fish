# Pure helper: compute the items list after inserting proj_pwd into Tide's
# left-prompt items. Replaces an existing `pwd` item in place; otherwise
# appends `proj_pwd`. Idempotent — input already containing `proj_pwd` is
# returned unchanged. Emits one item per line on stdout.

function _fish_weft_tide_insert_proj_pwd
    set -l items $argv

    if contains proj_pwd $items
        printf '%s\n' $items
        return 0
    end

    if contains pwd $items
        set -l idx (contains -i pwd $items)
        set -l new
        set -l before_end (math $idx - 1)
        set -l after_start (math $idx + 1)
        test $before_end -ge 1
            and set new $items[1..$before_end]
        set new $new proj_pwd
        test $after_start -le (count $items)
            and set new $new $items[$after_start..-1]
        printf '%s\n' $new
    else
        printf '%s\n' $items proj_pwd
    end
end
