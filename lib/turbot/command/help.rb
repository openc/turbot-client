#List commands and display help
#
class Turbot::Command::Help < Turbot::Command::Base
  PRIMARY_NAMESPACES = Set.new(%w(auth bots))

  # help [COMMAND]
  #
  #List available commands or display help for a specific command.
  #
  #Examples:
  #
  #  $ turbot help
  #  Usage: turbot COMMAND [--bot APP] [command-specific-options]
  #
  #  Primary help topics, type "turbot help TOPIC" for more details:
  #
  #    auth  #  Login or logout from Turbot
  #    bots  #  Manage bots (generate skeleton, validate data, submit code)
  #
  #  Additional topics:
  #
  #    help     #  List commands and display help
  #    version  #  Display version
  #
  #  $ turbot help auth:whoam
  #  Usage: turbot auth:whoami
  #
  #  Display your Turbot email address.
  #
  #  Example:
  #
  #   $ turbot auth:whoami
  #   email@example.com
  #
  def index
    command = args.shift
    if command
      help_for_command(command)
    else
      help_for_root
    end
  end
  alias_command '-h', 'help'
  alias_command '--help', 'help'

private

  def help_for(items, name_key, description_key)
    size = items.map { |namespace| namespace[name_key].size }.max
    items.sort_by { |namespace| namespace[name_key] }.each do |namespace|
      puts "  %-#{size}s  # %s" % [ namespace[name_key], namespace[description_key] ]
    end
  end

  ### Root

  def namespaces
    Turbot::Command.namespaces
  end

  def primary_namespaces
    namespaces.select { |name,_| PRIMARY_NAMESPACES.include?(name) }.values
  end

  def additional_namespaces
    namespaces.reject { |name,_| PRIMARY_NAMESPACES.include?(name) }.values
  end

  def summary_for_namespaces(namespaces)
    help_for(namespaces, :name, :description)
  end

  def help_for_root
    puts 'Usage: turbot COMMAND [--bot APP] [command-specific-options]'
    puts
    puts 'Primary help topics, type "turbot help TOPIC" for more details:'
    puts
    summary_for_namespaces(primary_namespaces)
    puts
    puts 'Additional topics:'
    puts
    summary_for_namespaces(additional_namespaces)
    puts
  end

  ### Command

  def commands
    Turbot::Command.commands
  end

  def commands_for_namespace(name)
    commands.values.select do |command|
      command[:namespace] == name && command[:command] != name
    end
  end

  def help_for_namespace(namespace_commands)
    help_for(namespace_commands, :banner, :summary)
  end

  def help_for_command(name)
    command_alias = Turbot::Command.command_aliases[name]
    if command_alias
      display "Alias: #{name} redirects to #{command_alias}"
      name = command_alias
    end

    command = commands[name]
    if command
      puts "Usage: turbot #{command[:banner]}"
      puts command[:help].split("\n").drop(1).join("\n")
      puts
    end

    namespace_commands = commands_for_namespace(name)
    if !namespace_commands.empty?
      puts 'Additional commands, type "turbot help COMMAND" for more details:'
      puts
      help_for_namespace(namespace_commands)
      puts
    elsif command.nil?
      error "#{name} is not a turbot command. See `turbot help`."
    end
  end
end
