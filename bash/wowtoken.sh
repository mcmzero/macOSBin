#!/bin/bash

[[ $1 ]] && watch -n $1 "curl -s http://wowtokenprices.com/current_prices.json|jq .korea.current_price"\
            || jq .korea.current_price <(curl -s http://wowtokenprices.com/current_prices.json)
