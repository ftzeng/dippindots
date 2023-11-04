# NOTE: import GPG private key
# see ~/docs/keys/note.md for password hint
# requires the `~/docs` directory has been restored
# gpg --import ~/docs/keys/private.key
# then:
# gpg --edit-key <KEY_ID>
# gpg> trust
# and set to ultimate trust

SHELL := /bin/bash
dir = ~/.dippindots

headless: prereqs git python rust headless-tools neovim misc-dots

laptop:\
	# deps
	prereqs git python rust node\

	# desktop environment
	bspwm lemonbar dunst dmenu theme\

	# apps
	headless-tools gui-tools neovim\
		kitty browser vpn\
		signal torrents keepass android\
		documents calendar neomutt\

	# media
	ffmpeg imagemagick audio feh mpv ncmpcpp scrots\

	# system config
	thinkpad tweaks screen language misc-dots

# ---

prereqs:
	@echo "Installing prereqs..."
	sudo apt update
	sudo apt upgrade -y
	sudo apt install -y --no-install-recommends python3 python3-pip python3-dev gcc gfortran build-essential g++ make cmake automake autoconf clang lld wget unzip git openssh-server software-properties-common libncurses5-dev libxml2-dev libxslt1-dev libyaml-dev bzip2 curl libsqlite3-dev gdebi libxcb-xinput-dev libxi-dev
	sudo apt install -y libatlas-base-dev liblapack-dev libopenblas-dev libopenblas-base libatlas3-base

	# Get rid of snap
	sudo rm -rf /var/cache/snapd/
	sudo apt autoremove --purge snapd
	rm -rf ~/snap
	echo "Package: snapd\nPin: release a=*\nPin-Priority: -10" | sudo tee -a /etc/apt/preferences.d/nosnap.pref
	sudo apt update

	# Get rid of some other unnecessary ubuntu server stuff
	sudo apt uninstall -y mdadm multipath-tools cloud-init

node:
	@echo "Installing nvm/node..."
	sudo pip install libsass
	curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.39.3/install.sh | bash
	nvm install node

headless-tools:
	@echo "Installing fzf..."
	@echo "Say NO to auto-completion for performance"
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
	~/.fzf/install

	sudo apt install -y --no-install-recommends wget curl jq htop tree cryptsetup silversearcher-ag dhcpcd5 gnupg dnsutils ncdu net-tools iw wireless-tools powertop dfc rename
	cargo install fd-find ripgrep jless

	# For LAN/local hostname resolution
	sudo apt install -y avahi-daemon libnss-mdns

gui-tools:
	# xsel - clipboard
	# xclip - clipboard, used by imgclip script
	# xdotool - simulating interactions with the GUI
	# i3lock - locking the screen
	# libnotify-bin - for `notify-send` to create notifications
	# unclutter - hide cursor after inactivity
	# gdebi - easier installation of deb packages
	sudo apt install -y xsel xclip xdotool i3lock libnotify-bin unclutter gdebi
	sudo apt install -y --no-install-recommends dos2unix imagemagick sqlitebrowser rclone
	sudo pip3 install -U yt-dlp
	cargo install xcolor # color picking
	cargo install pastel

	# for easily updating system time to current time zone
	# to preview, run `tzupdate -p`
	# to make the change, run `sudo tzupdate`
	sudo pip3 install -U tzupdate

git:
	@echo "Installing git..."
	sudo add-apt-repository ppa:git-core/ppa -y
	sudo apt update
	sudo apt install -y git

	curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
	sudo apt install -y git-lfs
	git lfs install

	mkdir -p ~/.config/git
	ln -sf $(dir)/dots/git/gitignore ~/.config/git/ignore
	ln -sf $(dir)/dots/git/gitconfig ~/.gitconfig

	# ssh access
	ssh -vT git@github.com

neovim:
	@echo "Installing neovim..."
	# Lua, python interps, and X11/system clipboard support
	sudo apt install -y \
		lua5.1 liblua5.1-dev \
		python3-dev \
		libx11-dev libxtst-dev libxt-dev \
		libsm-dev libxpm-dev \
		gettext

	wget https://github.com/neovim/neovim/archive/refs/tags/v0.9.1.tar.gz -O /tmp/neovim.tar.gz
	cd /tmp; tar -xzvf neovim.tar.gz; \
		cd neovim-*; make CMAKE_BUILD_TYPE=RelWithDebInfo && sudo make install \
			&& sudo ln -sf /usr/local/bin/nvim /usr/bin/vi \
			&& sudo ln -sf /usr/local/bin/nvim /usr/bin/vim \
			&& sudo ln -sf /usr/bin/vim /etc/alternatives/editor
	ln -sf $(dir)/dots/nvim ~/.config/nvim

rust:
	@echo "Installing rust..."
	curl -sf -L https://static.rust-lang.org/rustup.sh | sh
	rustup toolchain add nightly
	rustup component add rust-src --toolchain nightly
	rustup component add clippy --toolchain nightly
	rustup override set nightly
	curl -L https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz -o /tmp/rust-analyzer.gz
	gunzip /tmp/rust-analyzer.gz
	sudo mv /tmp/rust-analyzer /usr/local/bin/rust-analyzer
	sudo chmod +x /usr/local/bin/rust-analyzer
	source ~/.cargo/env

python:
	@echo "Installing python..."
	sudo apt -y install python3 python3-setuptools python3-pip

	# pyenv for easier version management
	sudo apt install -y --no-install-recommends build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python3-openssl git
	git clone https://github.com/pyenv/pyenv.git ~/.pyenv
	git clone https://github.com/pyenv/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv

	# install python
	env PYTHON_CFLAGS=-fPIC PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install 3.10.0
	pyenv global 3.10.0

ncmpcpp:
	# build the latest ncmpcpp
	sudo apt install -y libboost-all-dev libfftw3-dev doxygen libncursesw5-dev libtag1-dev libcurl4-openssl-dev libmpdclient-dev libtool
	git clone https://github.com/arybczak/ncmpcpp.git /tmp/ncmpcpp
	cd /tmp/ncmpcpp;\
		git checkout 0.9.2;\
		./autogen.sh;\
		autoreconf --force --install;\
		BOOST_LIB_SUFFIX="" ./configure --enable-visualizer --enable-outputs --with-taglib --with-fftw;\
		make && sudo make install
	ln -sf $(dir)/dots/ncmpcpp ~/.ncmpcpp

	sudo apt install -y mpd mpc
	mkdir ~/.mpd/
	touch ~/.mpd/{mpd.db,mpd.log,mpd.pid,mpd.state}
	ln -sf $(dir)/dots/mpd/mpd.conf ~/.mpd/mpd.conf
	sudo systemctl disable --now mpd # prevent conflicts with user instance
	sudo systemctl stop mpd.socket

ffmpeg:
	sudo apt install -y autoconf automake build-essential libfreetype6-dev libsdl1.2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev pkg-config texi2html zlib1g-dev libx264-dev libmp3lame-dev libfdk-aac-dev libvpx-dev libopus-dev libpulse-dev yasm libvidstab-dev libtool libwebp-dev libssl-dev libdav1d-dev

	# libass
	sudo apt install -y libfribidi-dev libfontconfig1-dev libharfbuzz-dev
	git clone --depth=1 https://github.com/libass/libass.git /tmp/libass
	cd /tmp/libass && ./autogen.sh && ./configure --enable-shared\
		&& make && sudo make install

	# NOTE: you need to make sure your ffmpeg included libs (e.g. livavutil)
	# match those needed by mpv.
	git clone --depth=1 --branch n4.4.4 git://source.ffmpeg.org/ffmpeg.git /tmp/ffmpeg

	# x265
	wget https://bitbucket.org/multicoreware/x265_git/downloads/x265_3.5.tar.gz -O /tmp/ffmpeg/x265.tar.gz
	cd /tmp/ffmpeg; tar -xzvf x265.tar.gz
	cd /tmp/ffmpeg/x265_*/build/linux\
		&& CFLAGS=-fPIC cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="/usr/local/ffmpeg" -DENABLE_SHARED:bool=on ../../source\
		&& make && sudo make install

	# vidstab
	git clone https://github.com/georgmartius/vid.stab.git /tmp/ffmpeg/vid.stab
	cd /tmp/ffmpeg/vid.stab && cmake . && make && sudo make install

	# compile ffmpeg
	cd /tmp/ffmpeg && \
	PKG_CONFIG_PATH="/usr/local/ffmpeg/lib/pkgconfig" ./configure \
		--prefix="/usr/local/ffmpeg" \
		--extra-cflags="-I/usr/local/ffmpeg/include" \
		--extra-ldflags="-L/usr/local/ffmpeg/lib" \
		--bindir="/usr/local/bin" \
		--cc="gcc -m64 -fPIC" \
		--enable-pic \
		--enable-gpl \
		--enable-x86asm \
		--enable-libass \
		--enable-libfdk-aac \
		--enable-libfreetype \
		--enable-libmp3lame \
		--enable-libopus \
		--enable-libtheora \
		--enable-libvorbis \
		--enable-libvpx \
		--enable-libx264 \
		--enable-libx265 \
		--enable-libpulse \
		--enable-libwebp \
		--enable-libdav1d \
		--enable-nonfree \
		--enable-openssl \
		--enable-shared \
		--enable-libvidstab \
		&& make && sudo make install\
		&& sudo sh -c "echo '/usr/local/ffmpeg/lib' > /etc/ld.so.conf.d/ffmpeg.conf"\
		&& sudo ldconfig

mpv:
	sudo apt install -y mpc mpv
	ln -sf $(dir)/dots/mpv ~/.config/mpv

	# mpvc for controlling mpv
	git clone --depth 1 https://github.com/lwilletts/mpvc.git /tmp/mpvc
	cd /tmp/mpvc && sudo make

audio:
	# Use pipewire. `pavucontrol` still works with pipewire.
	# Get a version of pipewire with support for the AAC bluetooth codec
	sudo add-apt-repository ppa:aglasgall/pipewire-extra-bt-codecs
	sudo apt update
	sudo apt install -y --no-install-recommends alsa-utils pavucontrol pulseaudio-utils pipewire pipewire-pulse wireplumber pipewire-audio-client-libraries libspa-0.2-bluetooth
	sudo touch /usr/share/pipewire/media-session.d/with-pulseaudio # Use pipewire as pulseaudio

	# bluetooth
	# see ~/notes/linux/bluetooth.md
	sudo apt install -y bluez libbluetooth3 libbluetooth-dev bluez-tools blueman

dmenu:
	git clone https://github.com/Cloudef/dmenu-pango-imlib /tmp/dmenu
	sudo apt install -y libxinerama-dev libimlib2-dev libxcb-xinerama0-dev libxft-dev libpango1.0-dev libssl-dev
	cd /tmp/dmenu && sudo make clean install

scrots:
	# maim/slop (scrot replacement)
	sudo apt install -y libglm-dev libgl1-mesa-dev libgles2-mesa-dev mesa-utils-extra \
		libxrandr-dev libxcomposite-dev libglew-dev libpng-dev libjpeg-dev libwebp-dev
	git clone https://github.com/naelstrof/slop.git /tmp/slop
	cd /tmp/slop\
		&& cmake -DCMAKE_OPENGL_SUPPORT=true -DSLOP_UNICODE=false ./\
		&& make && sudo make install
	git clone https://github.com/naelstrof/maim.git /tmp/maim
	cd /tmp/maim\
		&& cmake ./\
		&& make && sudo make install

	# for screen recordings
	sudo apt install -y recordmydesktop gifsicle

	# screenkey
	# press shift+shift to temporarily disable/renable
	pip3 install dbus-python
	pip3 install pip install git+https://gitlab.com/screenkey/screenkey

	# xrectsel for region selection (for recording regions)
	git clone https://github.com/lolilolicon/xrectsel.git /tmp/xrectsel
	cd /tmp/xrectsel && ./bootstrap\
		&& ./configure --prefix /usr\
		&& make && sudo make install

feh:
	# webp imlib2 loader
	sudo apt install -y libimlib2-dev libwebp-dev pkg-config
	git clone https://github.com/gawen947/imlib2-webp.git /tmp/webp
	cd /tmp/webp && make && sudo make install

	# for viewing svgs
	sudo apt install -y librsvg2-bin

	# feh - image viewer/wallpaper manager
	sudo apt install -y feh

yazi:
	cargo install --git https://github.com/sxyazi/yazi
	ln -sf $(dir)/dots/yazi  ~/.config/yazi

bspwm: # window manager
	sudo apt install -y --no-install-recommends xorg
	sudo apt install -y xcb libxcb-util0-dev libxcb-randr0-dev libxcb-icccm4-dev libxcb-keysyms1-dev  libxcb-xtest0-dev libasound2-dev libxcb-ewmh-dev
	git clone https://github.com/baskerville/xdo /tmp/xdo
	git clone https://github.com/baskerville/bspwm.git /tmp/bspwm
	git clone https://github.com/baskerville/sxhkd.git /tmp/sxhkd
	cd /tmp/xdo && make && sudo make install
	cd /tmp/bspwm && make && sudo make install
	cd /tmp/sxhkd && make && sudo make install
	ln -sf $(dir)/dots/bspwm  ~/.config/bspwm
	ln -sf $(dir)/dots/sxhkd  ~/.config/sxhkd

lemonbar: # status bar/panel
	sudo apt install -y xcb libxcb-xkb-dev x11-xkb-utils libx11-xcb-dev libxkbcommon-x11-dev libxtst-dev
	ln -sf $(dir)/dots/lemonbar  ~/.config/lemonbar
	sudo ln -sf ~/.config/lemonbar/panel /usr/bin/panel
	sudo ln -sf ~/.config/lemonbar/panel_bar /usr/bin/panel_bar
	sudo ln -sf ~/.config/lemonbar/panel_autohide /usr/bin/panel_autohide
	git clone https://github.com/baskerville/sutils.git /tmp/sutils
	git clone https://github.com/baskerville/xtitle.git /tmp/xtitle
	git clone https://github.com/drscream/lemonbar-xft /tmp/bar
	cd /tmp/sutils && make && sudo make install
	cd /tmp/xtitle && make && sudo make install
	cd /tmp/bar && make && sudo make install
	echo 'export PANEL_FIFO="/tmp/panel-fifo"' | sudo tee -a /etc/profile

dunst: # notifications
	sudo apt install -y libxss-dev libxdg-basedir-dev libxinerama-dev libxft-dev libcairo2-dev libdbusmenu-glib-dev libgtk2.0-dev
	wget https://github.com/dunst-project/dunst/archive/v1.3.1.zip -O /tmp/dunst.zip
	cd /tmp/ && unzip dunst.zip && cd dunst-*\
		&& make && sudo make install
	ln -sf $(dir)/dots/dunst  ~/.config/dunst

kitty: # terminal
	curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
	ln -sf $(dir)/dots/kitty/kitty.conf ~/.config/kitty/kitty.conf

imagemagick: # imagemagick with AVIF support
	git clone https://aomedia.googlesource.com/aom /tmp/aom
	cd /tmp/aom && git checkout tags/v3.5.0\
		&& mkdir aom_build && cd aom_build\
		&& cmake .. && make && sudo make install

	sudo apt install -y libde265-dev
	wget "https://github.com/strukturag/libheif/archive/refs/tags/v1.14.0.tar.gz" -O /tmp/libheif.tar.gz
	cd /tmp/ && tar -xzvf libheif.tar.gz && mv libheif-* libheif
	cd /tmp/libheif/third-party && bash aom.cmd
	cd /tmp/libheif && ./autogen.sh && ./configure\
		&& make && sudo make install

	wget "https://github.com/ImageMagick/ImageMagick/archive/refs/tags/7.1.0-53.tar.gz" -O /tmp/imagemagick.tar.gz
	cd /tmp/ && tar -xzvf imagemagick.tar.gz
	cd /tmp/ImageMagick-*\
		&& ./configure --with-heic=yes\
		&& make && sudo make install
	sudo ldconfig

browser:
	# Firefox Nightly
	wget "https://download.mozilla.org/?product=firefox-nightly-latest-ssl&os=linux64&lang=en-US" -O /tmp/firefox.tar.bz2
	cd /tmp/ && tar -xzvf firefox.tar.bz2
	sudo mv /tmp/firefox /opt/firefox
	sudo ln -s /opt/firefox/firefox /usr/local/bin/firefox

	# Google Chrome
	wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmour -o /usr/share/keyrings/google_linux_signing_key.gpg
	sudo sh -c 'echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
	sudo apt update
	sudo apt install google-chrome-stable

	# firefox config
	# In `about:config`, set:
	#   - `media.peerconnection.enabled` to false to prevent WebRTC IP leaks
	#   - `toolkit.legacyUserProfileCustomizations.stylesheets` to true
	#   - `browser.fullscreen.autohide` to false
	#   - `ui.systemUsesDarkTheme` to 1 (you may have to manually add this preference)
	#   - `dom.input.fallbackUploadDir` to `~/downloads` to stop it from trying to upload from `~/Desktop`
	# Also disabled hardware acceleration, had issues with slow painting otherwise
	mkdir -p ~/.mozilla/firefox/profile.default/chrome
	ln -sf $(dir)/dots/firefox/userChrome.css ~/.mozilla/firefox/profile.default/chrome/userChrome.css
	ln -sf $(dir)/dots/firefox/userContent.css ~/.mozilla/firefox/profile.default/chrome/userContent.css
	sed -i 's/Path=.*/Path=profile.default/' ~/.mozilla/firefox/profiles.ini # NOTE this file might not exist until you launch firefox
	# extensions
	# - https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/
	# - hili

	# Change default browser
	sudo update-alternatives --config x-www-browser
	sudo update-alternatives --config gnome-www-browser

	# [REMOVAL CANDIDATE]
	# flash player
	# sudo apt install -y pepperflashplugin-nonfree
	# sudo update-pepperflashplugin-nonfree --install

neomutt:
	sudo apt install -y xsltproc libidn11-dev libsasl2-dev libnotmuch-dev notmuch --no-install-recommends
	sudo pip install isync urlscan # isync is mbsync
	git clone https://github.com/neomutt/neomutt.git /tmp/neomutt
	cd /tmp/neomutt && git checkout neomutt-20180716\
		&& ./configure --disable-doc --ssl --sasl --notmuch\
		&& make && sudo make install
	sudo ln -s /usr/bin/neomutt /usr/bin/mutt
	ln -sf $(dir)/dots/email/muttrc ~/.muttrc
	ln -sf $(dir)/dots/email/mailcap ~/.mailcap
	ln -sf $(dir)/dots/email/mbsyncrc ~/.mbsyncrc
	ln -sf $(dir)/dots/email/notmuch-config ~/.notmuch-config
	ln -sf $(dir)/dots/email/signature ~/.signature
	sudo ln -sf $(dir)/dots/email/view_html.sh /usr/local/bin/view_html
	sudo ln -sf $(dir)/dots/email/view_mht.py /usr/local/bin/view_mht
	sudo ln -sf $(dir)/dots/email/update_nm.sh /usr/local/bin/update_nm

	mkdir ~/.mail
	sudo cp $(dir)/dots/email/mbsync.{service,timer} /etc/systemd/user/
	systemctl --user daemon-reload
	systemctl --user enable mbsync.timer
	systemctl --user start mbsync.timer

calendar:
	pip3 install vdirsyncer[google]
	mkdir -p ~/.config/vdirsyncer
	mkdir -p ~/.config/vdirsyncer/tokens
	sudo ln -sf $(shell which vdirsyncer) /usr/local/bin/vdirsyncer
	ln -sf $(dir)/dots/calendar/vdirsyncer ~/.config/vdirsyncer/config

	# NOTE: If you have issues here ("collection could not be created")
	# make sure the correct calendars are checked here: <https://calendar.google.com/calendar/u/0/syncselect>
	vdirsyncer discover

	sudo cp $(dir)/dots/calendar/vdirsyncer.{service,timer} /etc/systemd/user/
	systemctl --user daemon-reload
	systemctl --user enable vdirsyncer.timer
	systemctl --user start vdirsyncer.timer
	# check timers with `systemctl list-timers --all --user`

vpn: # wireguard & mullvad
	sudo apt install -y wireguard resolvconf
	wget "https://mullvad.net/fr/download/app/deb/latest" -O /tmp/mullvad.deb
	sudo gdebi /tmp/mullvad.deb
	ln -s "/opt/Mullvad VPN/mullvad-gui" /usr/local/bin/vpn

theme: # wallpaper, fonts, etc
	# GTK/QT themeing
	# Note that the font defined here is
	# what sets the `system-ui` font in browsers
	sudo apt install -y gnome-accessibility-themes
	mkdir ~/.config/gtk-3.0
	rm -rf ~/.icons
	ln -sf $(dir)/assets/icons ~/.icons
	ln -sf $(dir)/dots/misc/gtkrc ~/.gtkrc-2.0
	ln -sf $(dir)/dots/misc/gtkrc  ~/.config/gtk-3.0/settings.ini
	echo -e "[Qt]\nstyle=GTK+" >> ~/.config/Trolltech.conf
	gsettings set org.gnome.desktop.interface color-scheme prefer-dark

	# setup fonts
	sudo ln -sf /etc/fonts/conf.avail/50-user.conf /etc/fonts/conf.d/50-user.conf
	sudo apt install -y fonts-inconsolata xfonts-terminus ttf-mscorefonts-installer fonts-noto-color-emoji
	mkdir -p ~/.config/fontconfig
	ln -sf $(dir)/assets/fonts ~/.fonts
	ln -sf $(dir)/dots/misc/fonts.conf ~/.fonts.conf
	ln -sf $(dir)/dots/misc/fonts.conf ~/.config/fontconfig/fonts.conf
	mkfontdir ~/.fonts
	mkfontscale ~/.fonts
	xset +fp ~/.fonts/
	xset fp rehash
	fc-cache -fv

	sudo mkdir /usr/share/fonts/truetype/robotomono
	sudo wget --content-disposition -P /usr/share/fonts/truetype/robotomono https://github.com/googlefonts/RobotoMono/raw/main/fonts/ttf/RobotoMono-{Bold,BoldItalic,Italic,Light,LightItalic,Medium,MediumItalic,Regular,Thin,ThinItalic}.ttf?raw=true
	sudo fc-cache -fv

	# wallpapers
	ln -sf $(dir)/assets/walls ~/.walls
	ln -sf ~/.walls/1.jpg ~/.wall.jpg
	chmod 644 ~/.wall.jpg

thinkpad: # thinkpad-specific stuff
	# tlp for better battery life
	# also provides utility commands `bluetooth` and `wifi`
	# which are used elsewhere in scripts
	sudo add-apt-repository -y ppa:linrunner/tlp
	sudo apt update
	sudo apt install tlp --no-install-recommends
	sudo apt install acpi-call-dkms
	# replacement for tm-smapi-dkms
	git clone https://github.com/teleshoes/tpacpi-bat /tmp/tpacpi-bat
	cd /tmp/tpacpi-bat && ./install.pl

	sudo systemctl enable tlp.service

	# synaptics for touchpad
	sudo apt install -y xserver-xorg-input-synaptics

tweaks:
	# fixes for 5G wifi
	# set networking card region
	sudo apt install -y bcmwl-kernel-source
	sudo iw reg set US # Set CRDA region to US

	# Disable these for faster startup time
	sudo systemctl disable apt-daily.service
	sudo systemctl disable apt-daily-upgrade.service

	# Use more familiar network interface names (wlan0, eth0)
	# Some parts of the dotfiles expect names like wlan0
	sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"net.ifnames=0 biosdevname=0 acpi_osi=linux acpi_backlight=vendor\"/" /etc/default/grub
	sudo update-grub
	sudo update-initramfs -u

	# NOTE: You will need to edit `/etc/netplan/00-installer-config.wifi.yaml` and:
	# - Change the interface name to `wlan0`
	# - Add "optional: true" as part of its config, e.g.
	# 	...
	#	wlan0:
	#		optional: true
	#	...
	#	This will prevent waiting for the network blocking the startup sequence.

	# Setup passwordless sudo/root for certain commands
	sudo cp $(dir)/dots/misc/00_anarres /etc/sudoers.d/

	# Remove default home directories ("Desktop", etc)
	sudo sed -i 's/enabled=True/enabled=False/' /etc/xdg/user-dirs.conf

	# Not sure why these lines are in startx,
	# but they interfere with notifications for apps like Slack
	sudo sed -i 's/unset DBUS_SESSION_BUS_ADDRESS/#unset DBUS_SESSION_BUS_ADDRESS/' /usr/bin/startx
	sudo sed -i 's/unset SESSION_MANAGER/#unset SESSION_MANAGER/' /usr/bin/startx

	# map capslock to super
	# use right alt and right control as compose keys
	sudo sed -i 's/XKBOPTIONS=""/XKBOPTIONS="compose:ralt,compose:rctrl,caps:super"/' /etc/default/keyboard

	# larger font for boot tty
	sudo sed -i 's/FONTFACE=.*/FONTFACE="Terminus"/' /etc/default/console-setup
	sudo sed -i 's/FONTSIZE=.*/FONTSIZE="14x28"/' /etc/default/console-setup

	# lid close/switch
	# to enable `systemctl hybrid-sleep`,
	# which is durable to power loss,
	# you must disable secure boot in the BIOS.
	sudo apt install -y pm-utils xautolock
	# TODO auto replace?
	# sudo vi /etc/systemd/logind.conf
	# add:
	# HandleLidSwitch=hybrid-sleep
	# systemctl restart systemd-logind.service
	# Note that idle detection doesn't work w/o a DE
	# Instead using xautolock, see ~/.xinitrc

	# For xautolock, need to do `visudo` and add:
	# ftseng  ALL = NOPASSWD: /bin/systemctl suspend

	# auto-lock screen on sleep
	# https://wiki.archlinux.org/index.php/Power_management#Suspend.2Fresume_service_files
	sudo cp $(dir)/bin/lock /usr/bin/lock
	sudo cp $(dir)/dots/services/lock@.service /etc/systemd/system/lock@.service
	sudo chown root:root /etc/systemd/system/lock@.service
	systemctl enable lock@ftseng.service

	# In `~/.Xresources` you can specify the DPI with a line, e.g. `Xft.dpi: 166`
	# Look up the DPI here: <http://dpi.lv/>

	# For for X1 Nano G1
	# where there is crackling/static
	# when headphones are plguged in.
	sudo apt install -y alsa-tools
	# sudo hda-verb /dev/snd/hwC0D0 0x1d SET_PIN_WIDGET_CONTROL 0x0
	sudo cp $(dir)/dots/services/audio_fix.service /etc/systemd/system/hdaverb.service
	sudo systemctl enable hdaverb

	# for USB input devices
	sudo apt install linux-image-generic
	sudo update-initramfs -k all -c
	# then reboot

android:
	sudo apt install -y android-tools-adb
	git clone https://github.com/google/adb-sync /tmp/adb-sync
	sudo cp /tmp/adb-sync/adb-sync /usr/local/bin/

torrents:
	sudo add-apt-repository ppa:deluge-team/stable
	sudo apt update
	sudo apt install -y deluged deluge-console nicotine
	mkdir ~/.config/deluge
	ln -sf $(dir)/dots/misc/deluged.conf ~/.config/deluge/core.conf

documents:
	# pandoc
	sudo apt install -y --no-install-recommends texlive lmodern cm-super texlive-latex-recommended texlive-latex-extra texlive-plain-generic texlive-xetex
	wget https://github.com/jgm/pandoc/releases/download/3.1.4/pandoc-3.1.4-1-amd64.deb -O /tmp/pandoc.deb
	sudo gdebi --n /tmp/pandoc.deb

	# Fix soul.sty so it can be used with xelatex/unicode
	sudo sed -i 's/\\newfont\\SOUL@tt{ectt1000}/\\font\\SOUL@tt=[RobotoMono-Regular.ttf]/' /usr/share/texlive/texmf-dist/tex/generic/soul/soul.sty

	# for annotating pdfs
	sudo apt install -y --no-install-recommends xournal

	# mupdf-gl
	wget https://www.mupdf.com/downloads/archive/mupdf-1.22.2-source.tar.gz -O /tmp/mupdf.tar.gz
	cd /tmp && tar -xf mupdf.tar.gz

	# zathura and suckless tabbed
	sudo apt install zathura zathura-pdf-poppler suckless-tools

	# change background color
	# change keybindings
	# j: scroll down
	# k: scroll up
	# J: page down
	# K: page up
	cd /tmp/mupdf-* \
		&& sed -i 's/glClearColor(0.3f, 0.3f, 0.3f, 1);/glClearColor(0.125f, 0.125f, 0.125f, 1);/' platform/gl/gl-main.c\
		&& sed -i "s/case 'j'/case 'foo'/" platform/gl/gl-main.c\
		&& sed -i "s/case ' '/case 'j'/" platform/gl/gl-main.c\
		&& sed -i "s/case 'foo'/case ' '/" platform/gl/gl-main.c\
		&& sed -i "s/case 'k'/case 'foo'/" platform/gl/gl-main.c\
		&& sed -i "s/case 'b'/case 'k'/" platform/gl/gl-main.c\
		&& sed -i "s/case 'foo'/case 'b'/" platform/gl/gl-main.c\
		&& sed -i "s/case '\.'/case 'J'/" platform/gl/gl-main.c\
		&& sed -i "s/case ','/case 'K'/" platform/gl/gl-main.c\
		&& make && sudo make prefix=/usr/local install

	sudo apt install -y libreoffice libreoffice-writer

keepass:
	# for ~/.bin/keepass
	sudo apt install -y --no-install-recommends keepassx python3-gi
	/usr/bin/pip3 install pykeepass

	# for OTPs
	sudo apt install -y oathtool

language:
	# better chinese character support
	sudo apt install -y fonts-noto-cjk

	# chinese pinyin input
	# Hit CTRL+SPACE+LEFT_SHIFT, in that order
	sudo apt install -y fcitx fcitx-googlepinyin

signal:
	# signal desktop client
	wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > /tmp/signal-desktop-keyring.gpg
	cat /tmp/signal-desktop-keyring.gpg | sudo tee -a /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
	echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' |\
		sudo tee -a /etc/apt/sources.list.d/signal-xenial.list
	sudo apt update && sudo apt install -y signal-desktop

	# signal-cli
	# used by daemon script
	sudo apt install -y openjdk-17-jre
	wget "https://github.com/AsamK/signal-cli/releases/download/v0.11.3/signal-cli-0.11.3-Linux.tar.gz" -O /tmp/signal-cli.tar.gz
	cd /tmp && tar -xzvf signal-cli.tar.gz\
		&& sudo mv signal-cli-* /opt/signal-cli\
		&& sudo ln -sf /opt/signal-cli/bin/signal-cli /usr/local/bin/signal-cli

misc-dots:
	ln -sf $(dir)/dots/bash/bash_profile ~/.bash_profile
	ln -sf $(dir)/dots/bash/bashrc ~/.bashrc
	ln -sf $(dir)/dots/bash/inputrc ~/.inputrc
	ln -sf $(dir)/bin ~/.bin

	# other defaults
	ln -sf $(dir)/dots/xinitrc ~/.xinitrc
	ln -sf $(dir)/dots/Xresources ~/.Xresources

	# symlink notes and sites
	ln -sf $(dir)/dots/port ~/.port

screen:
	sudo apt install -y redshift
	sudo cp $(dir)/bin/glow /usr/bin/glow
	mkdir ~/.config/redshift

	# doesn't work as a symlink
	cp $(dir)/dots/misc/redshift.conf ~/.config/redshift/redshift.conf