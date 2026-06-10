# Resolve the fish-weft workspace root.
# Prefer AION_AUTOPOIESEON; fall back to the deprecated PROJECTS_DIR with a
# one-time warning per shell session. Returns 1 (no output) if neither is set.

function __fish_weft_workspace_root
    if set -q AION_AUTOPOIESEON
        echo $AION_AUTOPOIESEON
        return 0
    end

    if set -q PROJECTS_DIR
        __fish_weft_warn_projects_dir_deprecated
        echo $PROJECTS_DIR
        return 0
    end

    return 1
end

function __fish_weft_warn_projects_dir_deprecated
    set -q __fish_weft_projects_dir_warned; and return 0
    set -g __fish_weft_projects_dir_warned 1
    echo "fish-weft: \$PROJECTS_DIR is deprecated; use \$AION_AUTOPOIESEON." >&2
    echo "fish-weft: migrate with: set -Ux AION_AUTOPOIESEON \$PROJECTS_DIR; set -Ue PROJECTS_DIR" >&2
end
