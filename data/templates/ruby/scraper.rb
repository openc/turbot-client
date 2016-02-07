# -*- coding: utf-8 -*-

require 'json'
require 'turbotlib'

Turbotlib.log("Starting run...") # optional debug logging

(1...20).each do |n|
  data = {
    number: n,
    company: "Company #{n} Ltd",
    message: "Hello #{n}",
    sample_date: Time.now,
    source_url: "http://somewhere.com/#{n}"
  }
  # The Turbot specification simply requires us to output lines of JSON
  puts JSON.dump(data)
end
