#!/bin/bash
# VAAPI enable FFMPEG with ubuntu repository

WORK="$HOME/ffmpeg"
SOURCE="$WORK/source"
BUILD="$WORK/build"
BIN="$WORK/bin"

CUSTOMPKG=false
RECOMPILE=false
HWACCEL=""
INSTPKG=full

ESSENTIAL_PKG="autoconf automake build-essential cmake git libtool pkg-config texinfo zlib1g-dev curl"

BASIC_PKG="libass-dev libfreetype6-dev libvorbis-dev libva-dev"
BASIC_FLAG="--enable-gpl --enable-libass --enable-libfreetype --enable-libvorbis"

# Dependencies for ffplay(can obmit if compile for server)
DESKTOP_PKG="libsdl2-dev libvdpau-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev"
DESKTOP_FLAG="--enable-sdl2 --enable-vdpau"

# Common package(same as ubuntu original package)
COMMON_PKG="\
ladspa-sdk libbs2b-dev libcaca-dev libcdio-paranoia-dev flite1-dev libfontconfig1-dev libfribidi-dev libgme-dev libgsm1-dev libmysofa-dev libopenjp2-7-dev libopenmpt-dev \
libpulse-dev librubberband-dev librsvg2-dev libshine-dev libsnappy-dev libsoxr-dev libspeex-dev libssh-dev libtheora-dev libtwolame-dev libwavpack-dev libwebp-dev libxml2-dev libxvidcore-dev \
libzmq3-dev libzvbi-dev libomxil-bellagio-dev libopenal-dev libavc1394-dev libiec61883-dev libchromaprint-dev frei0r-plugins-dev libcodec2-dev libsmbclient-dev opencl-dev"
COMMON_FLAG="\
--enable-avresample --enable-avisynth --enable-ladspa --enable-libbs2b --enable-libcaca --enable-libcdio --enable-libflite --enable-libfontconfig --enable-libfribidi --enable-libgme \
--enable-libgsm --enable-libmysofa --enable-libopenjpeg --enable-libopenmpt --enable-libpulse --enable-librubberband --enable-librsvg --enable-libshine --enable-libsnappy --enable-libsoxr \
--enable-libspeex --enable-libssh --enable-libtheora --enable-libtwolame --enable-libwavpack --enable-libwebp --enable-libxml2 --enable-libxvid --enable-libzmq --enable-libzvbi --enable-omx \
--enable-openal --enable-opengl --enable-libdc1394 --enable-libdrm --enable-libiec61883 --enable-chromaprint --enable-frei0r --enable-libcodec2 --enable-libsmbclient --enable-version3  \
--enable-opencl"

# Custom compile library
REPO_PKG="nasm yasm libx264-dev libx265-dev libnuma-dev libvpx-dev libfdk-aac-dev libmp3lame-dev libopus-dev"
REPO_FLAG="--enable-libx264 --enable-libx265 --enable-libvpx --enable-libfdk-aac --enable-nonfree --enable-libmp3lame --enable-libopus --enable static --disable-shared"
CUSTOM_FLAG="--enable-libx264 --enable-libx265 --enable-libvpx --enable-libfdk-aac --enable-nonfree --enable-libmp3lame --enable-libopus"

# Flag for static custom compile library
STATIC_FLAG='\
--pkg-config-flags="--static" --prefix="$BUILD" --extra-cflags="-I$BUILD/include" --extra-ldflags="-L$BUILD/lib" --extra-cflags="-I/usr/local/include" --extra-ldflags="-L/usr/local/lib" --bindir="$BIN" \
--extra-libs=-lpthread --extra-version=18.04C'

# Package that can only compile with ubuntu repo package(shared)
SHARED_PKG="gnutls-dev libbluray-dev"
SHARED_FLAG="--enable-gnutls --enable-libbluray"

# hwaccel
VAAPI_FLAG="--enable-vaapi"

# Prepare work space directory
CREATE_WD() {
if [ ! -d "$SOURCE" ]; then
	mkdir -p "$SOURCE"
fi

if [ "$CUSTOMPKG" = false ] && [ ! -d "$BUILD" ]; then
	mkdir -p "$BUILD"
fi

if [ "$CUSTOMPKG" = false ] && [ ! -d "$BIN" ]; then
	mkdir -p "$BIN"
fi
}

# NASM
INST_NASM() {
cd "$SOURCE" && \
rsync -a --info=progress2 /home/public/Documents/source/nasm/ $SOURCE/nasm && cd nasm && \
./autogen.sh && ./configure --prefix="$BIN" --bindir="$BIN" && \
make -j$(nproc) VERBOSE=1 && make -j$(nproc) install && make -j$(nproc) distclean
}

# libx264
INST_LIBX264() {
cd "$SOURCE" && \
#git -C x264 pull 2> /dev/null || git clone --depth 1 https://git.videolan.org/git/x264 && cd x264 && \
rsync -a --info=progress2 /home/public/Documents/source/x264/ $SOURCE/x264 && cd x264 && \
PATH="$BIN:$PATH" PKG_CONFIG_PATH="$BUILD/lib/pkgconfig" ./configure --prefix="$BUILD" --bindir="$BIN" --enable-static --enable-pic && \
PATH="$BIN:$PATH" make -j$(nproc) && make -j$(nproc) install
}

# libx265
INST_LIBX265() {
sudo apt install -y mercurial libnuma-dev && \
cd "$SOURCE" && \
#if cd x265 2> /dev/null; then hg pull && hg update; else hg clone https://bitbucket.org/multicoreware/x265; fi && cd x265/build/linux && \
rsync -a --info=progress2 /home/public/Documents/source/x265/ $SOURCE/x265 && cd x265/build/linux && \
PATH="$BIN:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$BUILD" -DENABLE_SHARED=off ../../source && \
PATH="$BIN:$PATH" make -j$(nproc) && make -j$(nproc) install
}

# libfdk-aac
INST_LIBFDK-AAC() {
cd "$SOURCE" && \
#git -C fdk-aac pull 2> /dev/null || git clone --depth 1 https://github.com/mstorsjo/fdk-aac && cd fdk-aac
rsync -a --info=progress2 /home/public/Documents/source/fdk-aac/ $SOURCE/fdk-aac && cd fdk-aac && \
autoreconf -fiv && ./configure --prefix="$BUILD" --disable-shared && \
make -j$(nproc) && make -j$(nproc) install && make -j$(nproc) distclean
}

# libvpx
INST_LIBVPX() {
cd "$SOURCE" && \
#git -C libvpx pull 2> /dev/null || git clone https://chromium.googlesource.com/webm/libvpx && cd libvpx %% \
rsync -a --info=progress2 /home/public/Documents/source/libvpx/ $SOURCE/libvpx && cd libvpx && \
PATH="$BIN:$PATH" ./configure --prefix="$BUILD" --disable-examples --enable-runtime-cpu-detect --enable-vp9 --enable-vp8 --enable-postproc \
--enable-vp9-postproc --enable-multi-res-encoding --enable-webm-io --enable-better-hw-compatibility --enable-vp9-highbitdepth \
--enable-onthefly-bitpacking --enable-realtime-only --cpu=native --as=nasm && \
PATH="$BIN:$PATH" make -j$(nproc) && make -j$(nproc) install && make clean && make distclean
}

# libmp3lame
INST_LIBMP3LAME() {
cd "$SOURCE" && \
#curl -L https://sourceforge.net/projects/lame/files/latest/download | tar xz && cd "$(ls | grep lame-*)" && \
rsync -a --info=progress2 /home/public/Documents/source/lame-3.100/ $SOURCE/lame-3.100 && cd lame-3.100 && \
PATH="$BIN:$PATH" ./configure --prefix="$BUILD" --enable-nasm --disable-shared && \
PATH="$BIN:$PATH" make -j$(nproc) && make -j$(nproc) install && make distclean
}

# libaom
INST_LIBAOM() {
# Add --enable-libaom
cd "$SOURCE" && \
#git -C aom pull 2> /dev/null || git clone --depth 1 https://aomedia.googlesource.com/aom && \
rsync -a --info=progress2 /home/public/Documents/source/aom/ $SOURCE/aom && rm -rf aom_build
mkdir aom_build && cd aom_build && \
PATH="$BIN:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$BUILD" -DENABLE_SHARED=off -DENABLE_NASM=on ../aom && \
PATH="$BIN:$PATH" make -j$(nproc) && make -j$(nproc) install
}

# lipopus
INST_LIBOPUS() {
cd "$SOURCE" && \
#git -C opus pull 2> /dev/null || git clone --depth 1 https://github.com/xiph/opus.git && \
rsync -a --info=progress2 /home/public/Documents/source/opus/ $SOURCE/opus
cd opus && \
./autogen.sh && \
PATH="$BIN:$PATH" ./configure --prefix="$BUILD" --disable-shared && \
PATH="$BIN:$PATH" make -j$(nproc) && make -j$(nproc) install
}

# Compile FFMPEG
INST_FFMPEG() {
# Check if FFmpeg exist
if [ ! -d "$SOURCE/FFmpeg" ]; then
	#git clone https://github.com/FFmpeg/FFmpeg -b master && \
	rsync -a --info=progress2 /home/public/Documents/source/FFmpeg/ $SOURCE/FFmpeg && \
	cd $SOURCE/FFmpeg
fi
cd $SOURCE/FFmpeg
make clean && make distclean
if [ "$CUSTOMPKG" = true ]; then
	PATH="$BIN:$PATH" PKG_CONFIG_PATH="$BUILD/lib/pkgconfig" ./configure \
	--extra-version=18.04C --prefix="$BUILD" --pkg-config-flags="--static" --extra-cflags="-I$BUILD/include" \
	--extra-ldflags="-L$BUILD/lib" --extra-libs="-lpthread -lm" --bindir="$BIN" \
	$FLAGLIST && \
	PATH="$BIN:$PATH" make -j$(nproc) && make -j$(nproc) install
else
	./configure --prefix="$BUILD" --bindir="$BIN" --extra-version=18.04C $FLAGLIST && \
	make -j$(nproc) && make -j$(nproc) install
fi
}

# Custom package
INST_CUST() {
# Configure custom dependencies
if [ "$CUSTOMPKG" = true ]; then
	# Clean up previous repo package
	sudo apt autoremove -y $REPO_PKG --purge
	# Install custom dependencies
	INST_NASM
	INST_LIBX264
	INST_LIBX265
	INST_LIBVPX
	INST_LIBFDK-AAC
	INST_LIBMP3LAME
	INST_LIBOPUS
	# INST_LIBAOM			
fi
}

############################## MAIN SCRIPT ################################################

while getopts ":a: :c :h :o: :p: :r :s" option; do
	case $option in
		a)	HWACCEL+=("$OPTARG");;
		c)	CUSTOMPKG=true;;
		o)	OUTPUTDIR=$OPTARG;;
		p)	INSTPKG=$OPTARG;;
		r)	RECOMPILE=true;;
		h)	echo "Usage:"
			echo "a:	hwaccel {vaapi|opencl}"
			echo "c:	Custom package"
			echo "o:	Output directory, Default is $HOME/ffmpeg."; 
			echo "for full install use /usr/local"
			echo "p:	Package {full|minimal}"
			echo "r:	Recompile only"
			echo "h:	help"
			exit 0
			;;
		\?)	
			echo "Invalid option: -$OPTARG" >&2
			exit 1
			;;
		: )
			echo "Invalid option: -$OPTARG requires an argument" 1>&2
			;;
	esac
done

if [ -d "$OUTPUTDIR" ]; then
	if [ "$OUTPUTDIR" != "$WORK" ]; then
		BUILD="$OUTPUTDIR\bin"
		BIN="$OUTPUTDIR\build"
	fi
fi

# Configure size of package list and flags
case $INSTPKG in 
	full)
		PKGLIST="$ESSENTIAL_PKG $BASIC_PKG $DESKTOP_PKG $COMMON_PKG"
		FLAGLIST="$BASIC_FLAG $DESKTOP_FLAG $COMMON_FLAG"
		;;
	server)
		PKGLIST="$ESSENTIAL_PKG $BASIC_PKG $COMMON_PKG"
		FLAGLIST="$BASIC_FLAG $COMMON_FLAG"
		;;
	mini)
		PKGLIST="$ESSENTIAL_PKG $BASIC_PKG"
		FLAGLIST="$BASIC_FLAG"
		;;
esac

# Configure using repo or custom package
if [ "$CUSTOMPKG" = false ]; then
	PKGLIST="$PKGLIST $REPO_PKG $SHARED_PKG"
	FLAGLIST="$FLAGLIST $REPO_FLAG $SHARED_FLAG"
else
	FLAGLIST="$FLAGLIST $CUSTOM_FLAG"
fi
# Configure hwaccel flag
for hw in "${HWACCEL[@]}"; do
	shopt -s nocasematch
	if [ "$hw" = "vaapi" ]; then
		FLAGLIST="$FLAGLIST $VAAPI_FLAG"
	fi
done

if [ "$RECOMPILE" = false ]; then
	if [ ! -d "$SOURCE/FFmpeg" ]; then
		echo "Fresh install FFmpeg"
		# Install common dependencies
		sudo apt update && sudo apt upgrade -y && sudo apt dist-upgrade -y && \
		sudo apt install -y $PKGLIST
		# Create working directory
		CREATE_WD
		INST_CUST
		INST_FFMPEG
	else
		echo "$$SOURCE/FFMPEG exist ... please add -r for re-compile"
	fi
else
	if [ ! -d "$WORK" ]; then
		echo "Error"
		echo "Working directory not exist...!!"
	else
		echo "Re-Compile FFmpeg"
		#INST_CUST
		INST_FFMPEG
	fi
fi