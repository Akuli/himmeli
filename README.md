# Himmeli

This program can dim your screens in various ways.
The main use case is filtering away blue light,
so that the screen is less straining for your eyes and comfortable to look at.

This program only does the screen adjusting.
It is up to you to decide how you want to run it and set that up.
For example, you may want to set up something to run this program when you log in,
or perhaps every 3 minutes while you're logged in.

Currently this program assumes that you are using X11,
but Windows, MacOS and Wayland support may be added later.
If you need any of this, please create an issue on GitHub.

Features:
- Two ways (simple and RGB) to specify how the screen should be adjusted
- Specifying different screen states for different times
- Supports X11

This program is written in [my Jou programming language](https://github.com/Akuli/jou) :)


## Setup

1. Install Jou version 2026-01-06-0400 using [Jou's instructions](https://github.com/Akuli/jou/blob/2026-01-06-0400/README.md#setup).
    Newer versions of Jou may also work.
2. Install libraries: (please create a GitHub issue if you need help with this and you don't have `apt`)
    ```
    $ sudo apt install libxcb1-dev libxcb-randr0-dev
    ```
3. Clone the repository: `git clone https://github.com/Akuli/himmeli`
4. Go to the folder you cloned: `cd himmeli`
5. Compile: `jou -o himmeli src/main.jou`
6. Try it: `./himmeli 0.6` (use `./himmeli 1` to restore the defaults)
7. Configure something to run `himmeli` automatically in whatever way you want (see below)


## Usage

There are two main ways to specify how colors should be adjusted:
- **One number** between 0 and 1, e.g. `./himmeli 0.6`.
    This is probably what you want if you are looking for a blue light filter.
    This works so that 1 does nothing, 0 is a totally black screen,
    and values between 0 and 1 behave similarly to other blue light filtering programs.
    For example, `0.6` is suitable for normal computer use during a day.
- **Three numbers** can be given to specify multipliers for red, green and blue. For example,
    `./himmeli "1 1 1"` does nothing (everything is multiplied by 1),
    `./himmeli "1 1 0"` removes all blue light (probably not what you want), and
    `./himmeli "0 0 0"` refuses to give you a completely black screen unless you use `--allow-dark`.

If you want to always adjust your screen with `himmeli`,
configure something to run a `himmeli` command when you log in.
You probably need to specify a full path to the `himmeli` executable.
For example, to make your screen always comfy,
set the following command to run every time you log in:

```
/full/path/to/himmeli_folder/himmeli 0.6
```

You can also specify multiple states with `@` and a timestamp after each one:
`"0.6 @ 10"` applies `0.6` if you run the program at 10AM.
The values are linearly interpolated between the times that you specify.
For example, consider the following command:

```
$ ./himmeli "0.6 @ 22" "0.3 @ 23:30" "0.3 @ 6" "0.6 @ 7"
```

Here's what this does depending on the time of day.
(Yes, I wrote the same times using both conventions.)

| Time          | Time              | What the above command basically does     |
|---------------|-------------------|-------------------------------------------|
| 7:00 to 22:00 | 7 AM to 10 PM     | `./himmeli 0.6`                           |
| 22:30         | 10:30 PM          | `./himmeli 0.5`                           |
| 23:00         | 11 PM             | `./himmeli 0.4`                           |
| 23:30 to 6:00 | 11:30 PM to 6 AM  | `./himmeli 0.3`                           |
| 6:30          | 6:30 AM           | `./himmeli 0.45`                          |
| 7:00          | 7 AM              | `./himmeli 0.6`                           |

If you want to always adjust your screen with `himmeli` in this mode,
you probably want to also use `--loop 3min` or similar.
The `--loop` option causes `himmeli` to run "forever" (that is, until interrupted)
and adjust your screen periodically.
For example, to always update your screen according to the above table,
refreshing every 3 minutes,
set the following command to run every time you log in:

```
/full/path/to/himmeli_folder/himmeli --loop 3min "0.6 @ 22" "0.3 @ 23:30" "0.3 @ 6" "0.6 @ 7"
```

See also `./himmeli --help`.


## Similar projects

- [redshift](https://github.com/jonls/redshift) (no longer maintained)
- [gammastep](https://gitlab.com/chinstrap/gammastep) (fork of redshift with Wayland support)
- [wlsunset](https://github.com/kennylevinsen/wlsunset) (Wayland only)


## Name

In the Finnish language, "himmeli" means the Finnish variant of a [straw mobile](https://en.wikipedia.org/wiki/Straw_mobile).
It is similar to the informal word "hommeli" which means "thingy" or "contraption",
and "himmennin" which means a dimmer.

Thanks to [taahol](https://github.com/taahol) for the name suggestion.


## Tests

Run `./tests.sh`.
That script runs `./himmeli --dry-run` with various other arguments after it
and compares the output to hard-coded strings with `diff`.
This means that tests only check the behavior of `--dry-run`, and IMO that's fine.
