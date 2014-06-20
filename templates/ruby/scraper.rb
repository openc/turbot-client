require 'json'

(1...20).each do |n|
  data = {
    number: n,
    message: "Hello #{n}",
    sample_date: Time.now,
    source_url: "http://somewhere.com/#{n}"
  }
  # The Turbot specification simply requires us to output lines of JSON
  puts JSON.dump(data)
end
