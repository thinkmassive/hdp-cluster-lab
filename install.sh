#!/bin/bash

echo 'Installing nodejs, npm, & nvm'
brew install -g nvm npm
nvm install 0.12

echo ''
cd http-server
npm install

echo ''
cd ..
./webapp.sh
