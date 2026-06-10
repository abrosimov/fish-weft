function __proj_current_project
    set -l root (__fish_weft_workspace_root)
    or return 1
    set -l rel (string replace "$root/" '' -- $PWD)
    test "$rel" = "$PWD"; and return 1
    set -l project (string split '/' -- $rel)[1]
    echo "$project"
end
