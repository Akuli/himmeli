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
# them to actually adjust your screens.
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
    diff -u --color <(printf '%s\n' "$output") <("$@" 2>&1) || (echo ""; echo "Command at $0:$(caller | cut -d' ' -f1) failed: $@"; exit 1)

    # One green dot per successful test
    echo -ne "${GREEN}.${RESET}"
}

# TODO: delete this, use HIMMELI_OVERRIDE_TIME instead
function remove_details() {
    "$@" | sed 's/[0-9]\.[0-9][0-9]/x.xx/g'
}

section "Help"
help_text="$(cat <<'EOF'
Usage:
  ./himmeli [options] "STATE"
  ./himmeli [options] "STATE1 @ hh:mm" "STATE2 @ hh:mm" ...

Options:
  --help           this message
  --allow-dark     allow making the screen very dark
  --loop INTERVAL  adjust, wait, adjust again etc, INTERVAL is e.g. 5min or 1h
  --dry-run        don't adjust screens, describe what would be done

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

section "The --loop flag"
expect './himmeli: invalid loop time "asd", try e.g. 3min or 1h' from $himmeli --loop asd
expect './himmeli: invalid loop time "asd", try e.g. 3min or 1h' from $himmeli --loop=asd
expect './himmeli: invalid loop time "", try e.g. 3min or 1h' from $himmeli --loop ""
expect './himmeli: invalid loop time "", try e.g. 3min or 1h' from $himmeli --loop=
expect './himmeli: invalid loop time "h", try e.g. 3min or 1h' from $himmeli --loop h
expect './himmeli: invalid loop time "h", try e.g. 3min or 1h' from $himmeli --loop=h
expect './himmeli: invalid loop time "123123123123123123h", try e.g. 3min or 1h' from $himmeli --loop 123123123123123123h
expect './himmeli: invalid loop time "123123123123123123h", try e.g. 3min or 1h' from $himmeli --loop=123123123123123123h
expect './himmeli: missing time unit in loop time "3", try e.g. 3min or 1h' from $himmeli --loop 3
expect './himmeli: missing time unit in loop time "3", try e.g. 3min or 1h' from $himmeli --loop=3
expect './himmeli: loop time cannot be zero' from $himmeli --loop "0 minutes"
expect './himmeli: loop time cannot be zero' from $himmeli --loop "0 hours"
expect './himmeli: specifying loop time in seconds is not supported, use minutes or hours' from $himmeli --loop 1s
expect './himmeli: specifying loop time in seconds is not supported, use minutes or hours' from $himmeli --loop "1 sec"
expect './himmeli: specifying loop time in seconds is not supported, use minutes or hours' from $himmeli --loop 1second
expect './himmeli: specifying loop time in seconds is not supported, use minutes or hours' from $himmeli --loop "1 seconds"

HIMMELI_OVERRIDE_TIME=01:00 \
expect 'Would immediately apply visibility value 1.00.
Then wait 1 minute (until 01:01).
Then adjust again: apply visibility value 0.98.
Then wait 1 minute (until 01:02).
Then adjust again: apply visibility value 0.96.
Then wait 1 minute (until 01:03).
Then adjust again: apply visibility value 0.94.
Then wait 1 minute (until 01:04).
Then adjust again: apply visibility value 0.92.
And so on.' from $himmeli --loop "1 min" "1 @ 1" "0.4 @ 1:30"

HIMMELI_OVERRIDE_TIME=01:00 \
expect 'Would immediately apply visibility value 1.00.
Then wait 5 minutes (until 01:05).
Then adjust again: apply visibility value 0.90.
Then wait 5 minutes (until 01:10).
Then adjust again: apply visibility value 0.80.
Then wait 5 minutes (until 01:15).
Then adjust again: apply visibility value 0.70.
Then wait 5 minutes (until 01:20).
Then adjust again: apply visibility value 0.60.
And so on.' from $himmeli --loop "5 minutes" "1 @ 1" "0.4 @ 1:30"

HIMMELI_OVERRIDE_TIME=01:00 \
expect 'Would immediately apply visibility value 0.40.
Then wait 1 hour and 30 minutes (until 02:30).
Then adjust again: apply visibility value 0.50.
Then wait 1 hour and 30 minutes (until 04:00).
Then adjust again: apply visibility value 0.60.
Then wait 1 hour and 30 minutes (until 05:30).
Then adjust again: apply visibility value 0.70.
Then wait 1 hour and 30 minutes (until 07:00).
Then adjust again: apply visibility value 0.80.
And so on.' from $himmeli --loop 90min "0.4 @ 1" "0.8 @ 7"

HIMMELI_OVERRIDE_TIME=01:00 \
expect 'Would immediately multiply red by 0.80, green by 0.40 and blue by 0.00.
Then wait 2 hours (until 03:00).
Then adjust again: multiply red by 0.85, green by 0.55 and blue by 0.15.
Then wait 2 hours (until 05:00).
Then adjust again: multiply red by 0.90, green by 0.70 and blue by 0.30.
Then wait 2 hours (until 07:00).
Then adjust again: multiply red by 0.95, green by 0.85 and blue by 0.45.
Then wait 2 hours (until 09:00).
Then adjust again: multiply red by 1.00, green by 1.00 and blue by 0.60.
And so on.' from $himmeli --loop=2h "0.8 0.4 0 @ 1" "1 1 0.6 @ 9"

echo ""
echo ""
echo "All tests ok."
