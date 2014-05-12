require "turbot/command/help"

Turbot::Command::Help.group("Foo Group") do |foo|
  foo.command "foo:bar", "do a bar to foo"
  foo.space
  foo.command "foo:baz", "do a baz to foo"
end

class Turbot::Command::Foo < Turbot::Command::Base
  def bar
  end

  def baz
  end
end

