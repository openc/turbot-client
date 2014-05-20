require "turbot/command/base"

# manage bot config vars
#
class Turbot::Command::Config < Turbot::Command::Base

  # config
  #
  # display the config vars for an bot
  #
  # -s, --shell  # output config vars in shell format
  #
  #Examples:
  #
  # $ turbot config
  # A: one
  # B: two
  #
  # $ turbot config --shell
  # A=one
  # B=two
  #
  def index
    validate_arguments!

    vars = api.get_config_vars(bot)
    if vars.empty?
      display("#{bot} has no config vars.")
    else
      vars.each {|key, value| vars[key] = value.to_s.strip}
      if options[:shell]
        vars.keys.sort.each do |key|
          display(%{#{key}=#{vars[key]}})
        end
      else
        styled_header("#{bot} Config Vars")
        styled_hash(vars)
      end
    end
  end

  # config:set KEY1=VALUE1 [KEY2=VALUE2 ...]
  #
  # set one or more config vars
  #
  #Example:
  #
  # $ turbot config:set A=one
  # Setting config vars and restarting example... done, v123
  # A: one
  #
  # $ turbot config:set A=one B=two
  # Setting config vars and restarting example... done, v123
  # A: one
  # B: two
  #
  def set
    unless args.size > 0 and args.all? { |a| a.include?('=') }
      error("Usage: turbot config:set KEY1=VALUE1 [KEY2=VALUE2 ...]\nMust specify KEY and VALUE to set.")
    end

    vars = args.inject({}) do |vars, arg|
      key, value = arg.split('=', 2)
      vars[key] = value
      vars
    end

    action("Setting config vars and restarting #{bot}") do
      api.put_config_vars(bot, vars)
    end

    vars.each {|key, value| vars[key] = value.to_s}
    styled_hash(vars)
  end

  alias_command "config:add", "config:set"

  # config:get KEY
  #
  # display a config value for an bot
  #
  #Examples:
  #
  # $ turbot config:get A
  # one
  #
  def get
    unless key = shift_argument
      error("Usage: turbot config:get KEY\nMust specify KEY.")
    end
    validate_arguments!

    vars = api.get_config_vars(bot)
    key, value = vars.detect {|k,v| k == key}
    display(value.to_s)
  end

  # config:unset KEY1 [KEY2 ...]
  #
  # unset one or more config vars
  #
  # $ turbot config:unset A
  # Unsetting A and restarting example... done, v123
  #
  # $ turbot config:unset A B
  # Unsetting A and restarting example... done, v123
  # Unsetting B and restarting example... done, v124
  #
  def unset
    if args.empty?
      error("Usage: turbot config:unset KEY1 [KEY2 ...]\nMust specify KEY to unset.")
    end

    args.each do |key|
      action("Unsetting #{key} and restarting #{bot}") do
        api.delete_config_var(bot, key)
      end
    end
  end

  alias_command "config:remove", "config:unset"

end
