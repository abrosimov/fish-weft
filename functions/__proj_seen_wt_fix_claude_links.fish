function __proj_seen_wt_fix_claude_links
    set -l cmd (commandline -opc)
    test (count $cmd) -ge 3; and test "$cmd[2]" = wt; and test "$cmd[3]" = fix-claude-links
end
