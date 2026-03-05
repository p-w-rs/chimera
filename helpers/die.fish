#!/usr/bin/env fish

# helpers/die.fish — source this at the top of any script to get:
#
#   die [message]   print message + exit 1
#   run CMD…        run a command; on failure, print it and die
#
# Usage:
#   source (dirname (status filename))/helpers/die.fish
#   run doas parted ...
#   run doas mkfs.ext4 ...

function die
    set msg $argv
    test -n "$msg"; or set msg "fatal error"
    echo "ERROR: $msg" >&2
    exit 1
end

function run
    $argv
    or die "'$argv' failed"
end
