# Retro-BBS-Term
My script for connecting to retro BBSs on linux using qodem and tcpser for a bit of added retro-authenticity.

I'm running this on a Pop_OS! linux, and the `retroBBSterm.sh` script probably won't work super-well on yours without some modification. In particular, I've hard-coded a number of references to my home directory (`/home/cpknight`) which I'm guessing won't likely work well for you.

## Acknoweldgements...

- The `tcpser` here was ripped from [go4retro/tcpser](https://github.com/go4retro/tcpser) which itself is a fork from Jim Brian's tcpser. This is a modem emulator which give me the experience of using `AT` commands so that I can pretend to 'dial' BBS's the old-school way. I do appreciate this is somewhat redundant to the built-in capabilities of `qodem`, but this setup works well for me. 
	- Some other versions are floating around, eg. [FozzTexx/tcpser](https://github.com/fozztexx/tcpser). I'll be checking out the other versions later on to see if I can improve the functionality of this script. In due course. 

- The `qodem` here was ripped from [quodem.soutceforge.io](https://qodem.sourceforge.io/). Thanks to Autumn Lamonte and all contributors for this amazing version Qmodem, which I remember from my BBS'ing days in the 1990s! 
	- Some other versions are floating around which I should take a look at some point, eg. [cnmade/qodem](https://github.com/cnmade/qodem).

## Build `tcpser` `qodem`; install `socat` `kitty` ...

The script assumes that `tcpser` and `qodem` are subdirectories containing built binaries in sub-directories. I don't install these two tools into `/usr/local/bin` or anything, since my use of these two execcutables is pretty self-contained. 

- `tcpser` is easy to build; from the `Retro-BBS-Term` directory, probably just `cd tcpser`, `make clean` and `make` is all you need. This repo contains artifacts from the last time I built tcpser, so you'll definitely want to clean and re-build this.

- `qodem` is a bit trickier to build since you'll have to clean artifacts up and run `configure` before building. I had to install some libraries that were not included in my distro. :warning:  Running `qodem` by default creates all sorts of stuff in your home directory, so if you don't want that, it might be best to just run it through the script. From the `Retro-BBS-Term` directory:
	- `sudo apt install lib32ncurses-dev`
	- `sudo apt install ibgpm-dev`
	- `cd qodem ; ./configure`
	- `make clean ; make`

- `socat` needs to be installed, and this isn't the default on my distro:
	- `sudo apt install socat`

- `kitty` is also a requirement - cf. [kitty](https://sw.kovidgoyal.net/kitty/). 

## Using the `retroBBSterm.sh` script...

- I make a symbolic link to the `retroBBSterm.desktop` file so that I can double-click on an icon from my gnome desktop: 
```
ln -s /home/cpknight/Projects/Retro-BBS-Term/retroBBSterm.desktop /usr/share/applications/retroBBSterm.desktop
```
- But you can run the script from 

- When you first get into `qodem` you'll have to connect it to the 'modem' - use `Alt-9` to do this. An error message will pop up on the screen, which can be dismissed. Now you're talking to the modem. Use `AT` commands, eg:
	- `AT` should respond with an `OK`
	- `ATDT shsbbs.net` to 'dial' **Sharato's Heavenly Sphere**.
	- `ATDT canadianrebel.sytes.net:1981` to 'dial' the **Canadian Rebel BBS**.
	- `+++` while connected to get back to the 'modem' (eg. then do `ATH` to hangup).

- You should be able to use all of the functionality of `qodem`, but I have some notes and 'todos' below to work on.
	- :warning: Don't toggle the status line mode using `Alt-7` - this gets caught up in an error loop, which I'll have to look into and fix later on.

## Todo's...

- Remove hard-coded paths and make the script user-generic.
- Dig into things and improve the interaction between `socat` and `qodem`.
	- Probably related: `zmodem` file transfers don't work.
- Fix up this repo and add build and install scripts, etc.

