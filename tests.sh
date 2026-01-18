#!/bin/bash

# When any command fails, tests stop with a failure
set -e

GREEN="\x1b[32m"
RESET="\x1b[0m"

while [ $# != 0 ]; do
    case "$1" in
        --no-colors)
            GREEN=""
            RESET=""
            shift
            ;;
        *)
            echo "Usage: $0 [--no-colors]"
            exit 2
            ;;
    esac
done

command="jou -o himmeli src/main.jou"
echo "Compiling: $command"
$command

# Tests are always invoked through --dry-run, so there should be no way for
# them to do something during tests.
himmeli="./himmeli --dry-run"

function section() {
    echo ""
    echo -n "$1: "
}

function expect() {
    if [ "$2" != "from" ]; then
        echo "Usage: expect OUTPUT from COMMAND"
        exit 1
    fi

    local output="$1"
    shift 2
    diff -u --color <(printf '%s\n' "$output") <("$@" 2>&1) || (echo ""; echo "Command failed: $@"; exit 1)

    # One green dot per successful test
    echo -ne "${GREEN}.${RESET}"
}

function remove_details() {
    "$@" | sed 's/[0-9]\.[0-9][0-9]/x.xx/g'
}

section "Help"
help_text="$(cat <<'EOF'
Usage:
  ./himmeli [options] "STATE"
  ./himmeli [options] "STATE1 @ hh:mm" "STATE2 @ hh:mm" ...

Options:
  --help          this message
  --allow-dark    allow making the screen very dark
  --dry-run       don't adjust screens, describe what would be done

The simplest way to specify a state is a number between 0 and 1. Here 0 means
black screen, 1 means reset, and values between 0 and 1 filter out mostly blue
light. For example, I use 0.6 during the day to make the screen look comfy and
easy on my eyes.

The state can also be R, G and B numbers between 0 and 1 separated by spaces.
For example, "0.5 0.5 0.5" basically decreases brightness, and "1 1 0" filters
out all blue light (probably not what you want).

If you specify multiple states, they must have "@ hh:mm" (hour and minute) or
"@ hh" (hour) at the end to specify when the state should apply: "0.6 @ 22"
means that value 0.6 will be used if you run the command at 22:00 (10PM). The
values are interpolated at other times (linearly by default).
EOF
)"
expect "$help_text" from $himmeli --help

section "Bad states"
expect './himmeli: invalid state "" (try --help)' from $himmeli ""
expect './himmeli: invalid state "1 1" (try --help)' from $himmeli "1 1"
expect './himmeli: invalid state "1 1 1 1" (try --help)' from $himmeli "1 1 1 1"
expect './himmeli: invalid state "1 1 1 1 1" (try --help)' from $himmeli "1 1 1 1 1"
expect './himmeli: invalid state "inf" (try --help)' from $himmeli "inf"
expect './himmeli: invalid state "nan" (try --help)' from $himmeli "nan"
expect './himmeli: invalid state "-0.5" (try --help)' from $himmeli " -0.5"
expect './himmeli: invalid state "5" (try --help)' from $himmeli "5"
expect './himmeli: invalid state "1 1 -0.5" (try --help)' from $himmeli "1 1 -0.5"
expect './himmeli: invalid state "1 1 5" (try --help)' from $himmeli "1 1 5"
expect './himmeli: invalid state "5" (try --help)' from $himmeli "5 @ 12:34"
expect './himmeli: invalid state "1 1 5" (try --help)' from $himmeli "1 1 5 @ 12:34"

section "Totally wrong arguments"
expect './himmeli: please specify how to color the screen (try --help)' from $himmeli
expect './himmeli: unknown option "-1" (try --help)' from $himmeli -1
expect './himmeli: unknown option "--asdf" (try --help)' from $himmeli --asdf

section "Specifying time"
expect "./himmeli: when you specify multiple states, you must use '@' to specify a time for each state" from $himmeli "1" "1 @ 12:34"
expect "./himmeli: when you specify multiple states, you must use '@' to specify a time for each state" from $himmeli "1" "1 @ 12:34" "0.5 @ 23:45"
expect "./himmeli: a time cannot be specified if you give just one state (try --help)" from $himmeli "1 @ 12:34"
expect "./himmeli: a time cannot be specified if you give just one state (try --help)" from $himmeli "1 1 1 @ 12:34"
expect './himmeli: invalid time "23:78" (try --help)' from $himmeli "1 @ 12:34" "0.5 @ 23:78"
expect './himmeli: invalid time "-1:05" (try --help)' from $himmeli "1 @ 12:34" "0.5 @ -1:05"
expect './himmeli: invalid time "5:-1" (try --help)' from $himmeli "1 @ 12:34" "0.5 @ 5:-1"
expect './himmeli: invalid time "23 :45" (try --help)' from $himmeli "1 @ 12:34" "0.5 @ 23 :45"
expect './himmeli: invalid time "12:34:56" (try --help)' from $himmeli "1 @ 12:34" "0.5 @ 12:34:56"
expect 'Would multiply red by x.xx, green by x.xx and blue by x.xx.' from remove_details $himmeli '  1 1   1@12:34' '.6@   23:45 '
# Time is not octal when it has a leading zero, so 09 is allowed
expect 'Would multiply red by x.xx, green by x.xx and blue by x.xx.' from remove_details $himmeli '  1 1   1@12:34' '.6@   23:45 '
expect 'Would multiply red by x.xx, green by x.xx and blue by x.xx.' from remove_details $himmeli "0.5 @ 09:01 " "1 @ 9:2"

section "Simple and correct"
expect 'Would multiply red by 1.00, green by 0.23 and blue by 0.02.' from $himmeli 0.2
expect 'Would multiply red by 1.00, green by 0.57 and blue by 0.21.' from $himmeli 0.4
expect 'Would multiply red by 1.00, green by 0.76 and blue by 0.60.' from $himmeli 0.6
expect 'Would multiply red by 1.00, green by 0.86 and blue by 0.87.' from $himmeli 0.8
expect 'Would multiply red by 1.00, green by 1.00 and blue by 1.00.' from $himmeli 1

section "The --allow-dark flag"
# Flag missing
expect "./himmeli: refusing because \"0.01\" would make the screen very dark, use --allow-dark if that's really what you want" from $himmeli 0.01
expect "./himmeli: refusing because \"0.01\" would make the screen very dark, use --allow-dark if that's really what you want" from $himmeli "0.01 @ 12:34" "1 @ 23:45"
expect "./himmeli: refusing because \"0.01\" would make the screen very dark, use --allow-dark if that's really what you want" from $himmeli "1 @ 12:34" "0.01 @ 23:45"
# Flag given as needed
expect 'Would multiply red by 0.07, green by 0.00 and blue by 0.00.' from $himmeli 0.01 --allow-dark
expect 'Would multiply red by x.xx, green by x.xx and blue by x.xx.' from remove_details $himmeli --allow-dark "0.01 @ 12:34" "1 @ 23:45"
expect 'Would multiply red by x.xx, green by x.xx and blue by x.xx.' from remove_details $himmeli --allow-dark "1 @ 12:34" "0.01 @ 23:45"
# These should not trigger the --allow-dark mechanism
expect 'Would multiply red by 1.00, green by 0.00 and blue by 0.00.' from $himmeli "1 0 0"
expect 'Would multiply red by 0.00, green by 1.00 and blue by 0.00.' from $himmeli "0 1 0"
expect 'Would multiply red by 0.00, green by 0.00 and blue by 1.00.' from $himmeli "0 0 1"

echo ""
echo ""
echo "All tests ok."
