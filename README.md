# Himmeli

This program dims your screen in various ways.
The main use case is filtering away blue light,
so that the screen is less straining for eyes and comfortable to look at.

This program **only does the screen adjusting**.
It is up to you to decide how you want to run it and set that up.
For example, you may want to set up something to run this program when you log in,
or perhaps every 3 minutes while you're logged in.


## Features

Currently this program assumes that you are using X11,
but Windows, MacOS or Wayland support may be added later.
Please create a GitHub issue if you need it.

Features:
- Two ways to specify how the screen should be adjusted (see below)
- Supports X11
- Written in [my Jou programming language](https://github.com/Akuli/jou) :)


## Setup

1. Install Jou version 2025-12-14-0400 using [Jou's instructions](https://github.com/Akuli/jou/blob/2025-12-14-0400/README.md#setup).
    Newer versions of Jou may also work.
2. Install libraries: (please create a GitHub issue if you need help with this and you don't have `apt`)
    ```
    $ sudo apt install libxcb1-dev libxcb-randr0-dev
    ```
3. Clone the repository: `git clone https://github.com/Akuli/himmeli`
4. Go to the folder you cloned: `cd himmeli`
5. Compile: `jou -o himmeli himmeli.jou`
6. Run: `./himmeli 0.6` (use `./himmeli 1` to restore the settings back)


## Usage

There are two main ways to specify how colors should be adjusted:
- **One number** between 0 and 1, e.g. `./himmeli 0.6`.
    This is probably what you want if you are looking for a blue light filter.
    This works so that 1 does nothing, 0 is a totally black screen,
    and values between 0 and 1 behave similarly to other blue light filtering programs.
    For example, `0.6` is suitable for normal computer use during a day.
- **Three numbers** can be given to specify multipliers for red, green and blue. For example,
    `./himmeli 1 1 1` does nothing (everything is multiplied by 1),
    `./himmeli 1 1 0` removes all blue light (probably not what you want), and
    `./himmeli 0 0 0` refuses to give you a completely black screen unless you use `-f`/`--force`.

See also `./himmeli --help`.


## Similar projects

- [redshift](https://github.com/jonls/redshift) (no longer maintained)
- [gammastep](https://gitlab.com/chinstrap/gammastep) (fork of redshift)
- [wlsunset](https://github.com/kennylevinsen/wlsunset)


## Name

In Finnish, "himmeli" is an informal word that basically means "thingy".
A similar word "himmennin" means a dimmer.
Thanks to [taahol](https://github.com/taahol) for the name suggestion.
