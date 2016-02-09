module Turbot
  module Command
    extend Turbot::Helpers

    def self.load
      Dir[File.join(File.dirname(__FILE__), 'command', '*.rb')].each do |file|
        require file
      end
      unregister_commands_made_private_after_the_fact
    end

    def self.unregister_commands_made_private_after_the_fact
      commands.values.
        select { |c| c[:klass].private_method_defined? c[:method] }.
        each { |c| commands.delete(c[:command]) }
    end

    def self.commands
      @@commands ||= {}
    end

    def self.command_aliases
      @@command_aliases ||= {}
    end

    def self.files
      @@files ||= Hash.new {|hash,key| hash[key] = File.readlines(key).map {|line| line.strip}}
    end

    def self.namespaces
      @@namespaces ||= {}
    end

    def self.register_command(command)
      commands[command[:command]] = command
    end

    def self.register_namespace(namespace)
      namespaces[namespace[:name]] = namespace
    end

    def self.current_command
      @current_command
    end

    def self.validate_arguments!
      unless @invalid_arguments.empty?
        arguments = @invalid_arguments.map(&:inspect)
        if arguments.length == 1
          message = "Invalid argument: #{arguments.first}"
        else
          message = "Invalid arguments: #{arguments[0...-1].join(', ')} and #{arguments[-1]}"
        end
        run('help', [current_command])
        error message
      end
    end

    def self.prepare_run(cmd, args=[])
      command = parse(cmd)

      @current_command = cmd

      opts = {}
      invalid_options = []

      parser = OptionParser.new do |parser|
        # remove OptionParsers Officious['version'] to avoid conflicts
        # see: https://github.com/ruby/ruby/blob/trunk/lib/optparse.rb#L814
        parser.base.long.delete('version')
        (command && command[:options] || []).each do |option|
          parser.on(*option[:args]) do |value|
            opts[option[:name].gsub('-', '_').to_sym] = value
            ARGV.join(' ') =~ /(#{option[:args].map {|arg| arg.split(' ', 2).first}.join('|')})/
          end
        end
      end

      begin
        parser.order!(args) do |nonopt|
          invalid_options << nonopt
        end
      rescue OptionParser::InvalidOption => e
        invalid_options << e.args.first
        retry
      end

      args.concat(invalid_options)

      @invalid_arguments = invalid_options

      if command
        command_instance = command[:klass].new(args.dup, opts.dup)
        [ command_instance, command[:method] ]
      else
        error([
          "`#{cmd}` is not a turbot command.",
          suggestion(cmd, commands.keys + command_aliases.keys),
          'See `turbot help` for a list of available commands.'
        ].compact.join("\n"))
      end
    end

    def self.run(command, arguments=[])
      begin
        object, method = prepare_run(command, arguments.dup)
        object.send(method)
      rescue Interrupt, StandardError, SystemExit => error
        # load likely error classes, as they may not be loaded yet due to defered loads
        require 'rest_client'
        raise(error)
      end
    rescue SocketError => e
      error 'Unable to connect to Turbot API, please check internet connectivity and try again.'
    rescue OptionParser::ParseError
      if commands[command]
        run('help', [command])
      else
        run('help')
      end
    end

    def self.parse(command)
      commands[command] || commands[command_aliases[command]]
    end

    def self.extract_error(body, options = {})
      if block_given?
        default_error = yield
      else
        default_error = 'Internal server error'
      end
      parse_error_json(body) || default_error
    end

    def self.parse_error_json(body)
      begin
        JSON.load(body.to_s)['message']
      rescue JSON::ParserError
        nil
      end
    end

  private

    def self.suggestion(actual, possibilities)
      distances = Hash.new { |hash,key| hash[key] = [] }
      possibilities.each do |possibility|
        distances[Text::Levenshtein.distance(actual, possibility, 4)] << possibility
      end
      minimum_distance = distances.keys.min
      if minimum_distance < 4
        suggestions = distances[minimum_distance].sort
        if suggestions.length == 1
          "Perhaps you meant `#{suggestions.first}`."
        else
          "Perhaps you meant #{suggestions[0...-1].map { |suggestion| "`#{suggestion}`" }.join(', ')} or `#{suggestions.last}`."
        end
      end
    end
  end
end
