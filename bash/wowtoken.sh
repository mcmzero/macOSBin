#!/bin/bash

function current_price() {
	jq .korea.current_price <(curl -s http://wowtokenprices.com/current_prices.json)
}
current_price
