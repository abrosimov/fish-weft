function __proj_seen_gc
    set -l cmd (commandline -opc)
    test (count $cmd) -ge 2; and test "$cmd[2]" = gc
end
