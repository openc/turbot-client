RSpec::Matchers.define :equal_lines do |expected|
  match do |actual|
    actual.split(/\r?\n/) == expected.split(/\r?\n/)
  end
end
