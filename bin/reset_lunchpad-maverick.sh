#!/bin/sh

mv ~/Library/Application\ Support/Dock{,.backup}
defaults write com.apple.dock ResetLaunchPad -bool true; killall Dock
