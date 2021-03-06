#!/bin/bash
#
# D++ Windows Bot Template
# (C) Craig Edwards 2021
#
# This script is run on a 15 minute cron by a github action.
# It uses the github client with an organisation token to pull the CI artifacts of the
# last successful CI build on master, and then unzip the windows builds.
# Once the windows builds are unzipped, it extracts the include directory from the 64
# bit release build, and the dlls/libs from all 4 builds, placing them in the correct
# locations in this repository. If they have been changed, this triggers a `git commit`
# followed by a `git push`.
# This script assumes `gh` is authenticated with a usable token and `git` has an SSH
# key ready to use for pushing, and that the checked out `main` branch is current.
# It also assumes nobody has renamed the CI jobs or the artifacts they export as these
# names have to be hard coded into the script.
#
echo "Fetching latest DPP"
mkdir temp
cd temp || exit
echo "Download assets from CI..."
gh run list -w "D++ CI" -R "brainboxdotcc/DPP" | grep $'\t'master$'\t' | grep ^completed | head -n1
gh run download -R "brainboxdotcc/DPP" $(gh run list -w "D++ CI" -R "brainboxdotcc/DPP" | grep $'\t'master$'\t' | grep ^completed | head -n1 | awk '{ printf $(NF-2) }')

echo "Process windows x64 release"
cd "./libdpp - Windows x64-Release" && unzip -qq ./*.zip
# header files from first zip
cp -rv ./*/include ../../MyBot/dependencies/

# dll files
cp -rv ./*/bin/*.dll ../../MyBot/dependencies/64/release/bin/
# lib files
cp -rv ./*/lib ../../MyBot/dependencies/64/release/
cd .. || exit

echo "Process windows x64 debug"
cd "./libdpp - Windows x64-Debug" && unzip -qq ./*.zip
# dll files
cp -rv ./*/bin/*.dll ../../MyBot/dependencies/64/debug/bin/
# lib files
cp -rv ./*/lib ../../MyBot/dependencies/64/debug/
cd .. || exit

echo "Process windows x86 release"
cd "./libdpp - Windows x86-Release" && unzip -qq ./*.zip
# dll files
cp -rv ./*/bin/*.dll ../../MyBot/dependencies/32/release/bin/
# lib files
cp -rv ./*/lib ../../MyBot/dependencies/32/release/
cd .. || exit

echo "Process windows x86 debug"
cd "./libdpp - Windows x86-Debug" && unzip -qq ./*.zip
# dll files
cp -rv ./*/bin/*.dll ../../MyBot/dependencies/32/debug/bin/
# lib files
cp -rv ./*/lib ../../MyBot/dependencies/32/debug/
cd .. || exit

echo "Converting linefeeds from dos to unix"
# dos2unix
cd .. || exit
cd MyBot/dependencies/include/dpp-9.0/dpp || exit
find . -exec dos2unix {} \;
cd ../../../../.. || exit
find . -name '*.cmake' -exec dos2unix -q {} \;

echo "Cleaning up..."
rm -rf temp

echo "Committing..."
git add -A MyBot/dependencies
git commit -m "auto update to latest DPP master branch"
git push

