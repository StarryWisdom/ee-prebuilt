#!/bin/bash

#build EE is mostly for reference - this is only needed once per EE release, then is uploaded to the s3 location

build_ee () {
	export THREADS=1 #probably should be set somehow from autodectecting number of cores, may be worth considering ninja instead of make
	cd ~
	sudo apt-get update
	yes Y | sudo apt-get install unzip
	yes Y | sudo apt-get install git build-essential libx11-dev cmake libxrandr-dev mesa-common-dev libglu1-mesa-dev libudev-dev libglew-dev libjpeg-dev libfreetype6-dev libopenal-dev libsndfile1-dev libxcb1-dev libxcb-image0-dev
	wget http://www.sfml-dev.org/files/SFML-2.5.1-sources.zip 
	unzip SFML-2.5.1-sources.zip 
	cd SFML-2.5.1
	cmake . 
	make -j $THREADS

	#now build EE
	cd ~
	#the apt-get will replace the above build of sfml, when 2.5 is avaible on the ubuntu AWS image
	#yes Y | sudo apt-get install libsfml-dev
	mkdir -p emptyepsilon && cd emptyepsilon
	export EE_VER=EE-2020.02.18
	export EE_MAJOR=2020
	export EE_MINOR=02
	export EE_PATCH=18
	git clone --branch $EE_VER https://github.com/daid/SeriousProton.git
	git clone --branch $EE_VER https://github.com/daid/EmptyEpsilon.git
	cd EmptyEpsilon && mkdir -p _build && cd _build
	#default build type (release)
	cmake .. -DSERIOUS_PROTON_DIR=$PWD/../../SeriousProton/ -DCPACK_PACKAGE_VERSION_MAJOR=$EE_MAJOR -DCPACK_PACKAGE_VERSION_MINOR=$EE_MINOR -DCPACK_PACKAGE_VERSION_PATCH=$EE_PATCH -DSFML_ROOT=~/SFML-2.5.1
	make -j $THREADS
	mv ./EmptyEpsilon ../EmptyEpsilon.Release
	#now build the debug version
	cmake .. -DSERIOUS_PROTON_DIR=$PWD/../../SeriousProton/ -DCPACK_PACKAGE_VERSION_MAJOR=$EE_MAJOR -DCPACK_PACKAGE_VERSION_MINOR=$EE_MINOR -DCPACK_PACKAGE_VERSION_PATCH=$EE_PATCH -DCMAKE_BUILD_TYPE=DEBUG -DSFML_ROOT=~/SFML-2.5.1
	make -j $THREADS
	mv ./EmptyEpsilon ../EmptyEpsilon.Debug
	cd ..
	cp ~/SFML-2.5.1/lib/* .

	#remove junk files not needed
	rm -rf .git _build
	cd ..
	tar -czf EmptyEpsilon.tar.gz EmptyEpsilon
	# may be worthwhile checksumming on both sides to confirm
	# curl --upload-file ./EmptyEpsilon.tar.gz https://transfer.sh/EmptyEpsilon.tar.gz
	# you will then get a url to download with
}