function __proj_base_dir
    set -l root (__fish_weft_workspace_root)
    or return 1
    set -l project (__proj_current_project)
    or return 1
    echo "$root/$project/base"
end
