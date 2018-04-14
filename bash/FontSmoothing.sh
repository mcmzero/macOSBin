#!/bin/sh

FONT_SMOOTHING_VALUE=3
defaults -currentHost delete -globalDomain AppleFontSmoothing
#defaults -currentHost write -globalDomain AppleFontSmoothing -int $FONT_SMOOTHING_VALUE
defaults -currentHost read -globalDomain AppleFontSmoothing
