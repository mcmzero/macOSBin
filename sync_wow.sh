#!/bin/sh

PATH_WIN=/Volumes/Redstone3/Games
PATH_MAC=/Volumes/Games
PATH_ADDONS=/World\ of\ Warcraft/Interface
PATH_ACCOUNT=/World\ of\ Warcraft/WTF

rm -rfv "$PATH_MAC$PATH_ADDONS/AddOns" "$PATH_MAC$PATH_ACCOUNT/Account"
cp -af "$PATH_WIN$PATH_ADDONS/AddOns" "$PATH_MAC$PATH_ADDONS"
cp -af "$PATH_WIN$PATH_ACCOUNT/Account" "$PATH_MAC$PATH_ACCOUNT"
