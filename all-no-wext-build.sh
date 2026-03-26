#!/bin/bash

cd /github/workspace
./configure --disable-linxwext --enable-wifi-coconut --enable-bladerf --enable-protobuf --enable-require-pcre2
make -j$(nproc)
sudo make suidinstall
