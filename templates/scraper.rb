require 'json'

(1...20).each do |n|
  data = {number: n, message: "Hello #{n}"}
  puts JSON.dump(data)
end
