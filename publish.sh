#!/bin/bash

gem build turbot.gemspec
gem push $(ls *gem|tail -1)

function clean {
 rm *gem
}
trap clean EXIT
