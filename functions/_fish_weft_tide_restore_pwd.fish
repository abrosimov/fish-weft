# Pure helper: compute the items list after replacing `proj_pwd` with the
# Tide built-in `pwd`. No-op if `proj_pwd` is absent. Emits one item per line
# on stdout.

function _fish_weft_tide_restore_pwd
    set -l items $argv

    if not contains proj_pwd $items
        printf '%s\n' $items
        return 0
    end

    set -l idx (contains -i proj_pwd $items)
    set -l new
    set -l before_end (math $idx - 1)
    set -l after_start (math $idx + 1)
    test $before_end -ge 1
        and set new $items[1..$before_end]
    set new $new pwd
    test $after_start -le (count $items)
        and set new $new $items[$after_start..-1]
    printf '%s\n' $new
end
