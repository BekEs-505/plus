#!/bin/sh

apt-ftparchive packages ./debs > Packages

awk -v h="Header: https://raw.githubusercontent.com/BekEs-505/plus/main/header.png" \
    '/^Package:/{print; print h; next}1' Packages > Packages.tmp && mv Packages.tmp Packages

git add --all
git commit -m "Init"
git push