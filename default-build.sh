#!/bin/bash

cd /github/workspace
./configure
make -j$(nproc)
sudo make suidinstall
