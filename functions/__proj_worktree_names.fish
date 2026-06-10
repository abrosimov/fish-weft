function __proj_worktree_names
    set -l root (__fish_weft_workspace_root)
    or return
    set -l project (__proj_current_project)
    or return
    for d in $root/$project/*/
        set -l name (basename $d)
        if test "$name" != base
            echo $name
        end
    end
end
