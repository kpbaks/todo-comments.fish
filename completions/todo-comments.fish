set -l c complete --command todo-comments

$c -s h -l help -d "Show help message and quit"
$c -s v -l verbose -d "Print the rg command that will be run"
$c -s t -l todo -d "Search for TODO comments"
$c -s f -l fixme -d "Search for FIXME comments"
$c -s n -l note -d "Search for NOTE comments"
$c -s i -l idea -d "Search for IDEA comments"
$c -s b -l bug -d "Search for BUG comments"
$c -s p -l perf -d "Search for PERF comments"

$c -s e -l extension -x -d "Search for files with the given extension(s)."
$c -s E -l exclude -x -d "Exclude files with the given extension(s)."

$c -s F -l fzf -d "Use fzf to select the file and line to open in \$EDITOR"
