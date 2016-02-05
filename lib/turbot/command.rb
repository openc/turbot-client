require 'turbot/helpers'
require 'turbot/version'
require "optparse"
require 'excon'

module Turbot
  module Command
    class CommandFailed  < RuntimeError; end

    extend Turbot::Helpers

    def self.load
      Dir[File.join(File.dirname(__FILE__), "command", "*.rb")].each do |file|
        require file
      end
      unregister_commands_made_private_after_the_fact
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

    def self.unregister_commands_made_private_after_the_fact
      commands.values \
        .select { |c| c[:klass].private_method_defined? c[:method] } \
        .each   { |c| commands.delete c[:command] }
    end

    def self.register_namespace(namespace)
      namespaces[namespace[:name]] = namespace
    end

    def self.current_command
      @current_command
    end

    def self.current_command=(new_current_command)
      @current_command = new_current_command
    end

    def self.current_args
      @current_args
    end

    def self.current_options
      @current_options ||= {}
    end

    def self.global_options
      @global_options ||= []
    end

    def self.invalid_arguments
      @invalid_arguments
    end

    def self.shift_argument
      # dup argument to get a non-frozen string
      @invalid_arguments.shift.dup rescue nil
    end

    def self.validate_arguments!
      unless invalid_arguments.empty?
        arguments = invalid_arguments.map {|arg| "\"#{arg}\""}
        if arguments.length == 1
          message = "Invalid argument: #{arguments.first}"
        elsif arguments.length > 1
          message = "Invalid arguments: "
          message << arguments[0...-1].join(", ")
          message << " and "
          message << arguments[-1]
        end
        $stderr.puts(format_with_bang(message))
        run(current_command, ["--help"])
        exit(1)
      end
    end

    def self.warnings
      @warnings ||= []
    end

    def self.display_warnings
      unless warnings.empty?
        $stderr.puts(warnings.map {|warning| " !    #{warning}"}.join("\n"))
      end
    end

    def self.global_option(name, *args, &blk)
      # args.sort.reverse gives -l, --long order
      global_options << { :name => name.to_s, :args => args.sort.reverse, :proc => blk }
    end

    global_option :bot, "-b", "--bot APP" do |bot|
      raise OptionParser::InvalidOption.new(bot) if bot == "pp"
    end
    global_option :help,    "-h", "--help"

    def self.prepare_run(cmd, args=[])
      command = parse(cmd)

      if args.include?('-h') || args.include?('--help')
        args.unshift(cmd) unless cmd =~ /^-.*/
        cmd = 'help'
        command = parse(cmd)
      end

      if cmd == '--version'
        cmd = 'version'
        command = parse(cmd)
      end

      @current_command = cmd
      @anonymized_args, @normalized_args = [], []

      opts = {}
      invalid_options = []

      parser = OptionParser.new do |parser|
        # remove OptionParsers Officious['version'] to avoid conflicts
        # see: https://github.com/ruby/ruby/blob/trunk/lib/optparse.rb#L814
        parser.base.long.delete('version')
        (global_options + (command && command[:options] || [])).each do |option|
          parser.on(*option[:args]) do |value|
            if option[:proc]
              option[:proc].call(value)
            end
            opts[option[:name].gsub('-', '_').to_sym] = value
            ARGV.join(' ') =~ /(#{option[:args].map {|arg| arg.split(' ', 2).first}.join('|')})/
            @anonymized_args << "#{$1} _"
            @normalized_args << "#{option[:args].last.split(' ', 2).first} _"
          end
        end
      end

      begin
        parser.order!(args) do |nonopt|
          invalid_options << nonopt
          @anonymized_args << '!'
          @normalized_args << '!'
        end
      rescue OptionParser::InvalidOption => ex
        invalid_options << ex.args.first
        @anonymized_args << '!'
        @normalized_args << '!'
        retry
      end

      args.concat(invalid_options)

      @current_args = args
      @current_options = opts
      @invalid_arguments = invalid_options

      if command
        command_instance = command[:klass].new(args.dup, opts.dup)

        if !@normalized_args.include?('--bot _') && (implied_bot = command_instance.bot rescue nil)
          @normalized_args << '--bot _'
        end
        @normalized_command = [ARGV.first, @normalized_args.sort_by {|arg| arg.gsub('-', '')}].join(' ')

        [ command_instance, command[:method] ]
      else
        error([
          "`#{cmd}` is not a turbot command.",
          suggestion(cmd, commands.keys + command_aliases.keys),
          "See `turbot help` for a list of available commands."
        ].compact.join("\n"))
      end
    end

    def self.run(cmd, arguments=[])
      begin
        object, method = prepare_run(cmd, arguments.dup)
        object.send(method)
      rescue Interrupt, StandardError, SystemExit => error
        # load likely error classes, as they may not be loaded yet due to defered loads
        require 'rest_client'
        raise(error)
      end
    rescue Turbot::API::Errors::Unauthorized, RestClient::Unauthorized
      puts "Authentication failure"
      if ENV['TURBOT_API_KEY']
        exit 1
      else
        run "login"
        retry
      end
    rescue Turbot::API::Errors::NotFound => e
      error extract_error(e.response.body) {
        e.response.body =~ /^([\w\s]+ not found).?$/ ? $1 : "Resource not found"
      }
    rescue RestClient::ResourceNotFound => e
      error extract_error(e.http_body) {
        e.http_body =~ /^([\w\s]+ not found).?$/ ? $1 : "Resource not found"
      }
    rescue RestClient::PaymentRequired => e
      # We've repurposed a 402 as a general error
      error extract_error(e.http_body)
    rescue Turbot::API::Errors::Timeout, RestClient::RequestTimeout
      error "API request timed out. Please try again, or contact support@turbot.com if this issue persists."
    rescue Turbot::API::Errors::ErrorWithResponse => e
      error extract_error(e.response.body)
    rescue RestClient::RequestFailed => e
      error extract_error(e.http_body)
    rescue CommandFailed => e
      error e.message
    rescue OptionParser::ParseError
      commands[cmd] ? run("help", [cmd]) : run("help")
    rescue Excon::Errors::SocketError, SocketError => e
      error("Unable to connect to Turbot API, please check internet connectivity and try again.")
    ensure
      display_warnings
    end

    def self.parse(cmd)
      commands[cmd] || commands[command_aliases[cmd]]
    end

    def self.extract_error(body, options={})
      default_error = block_given? ? yield : "Internal server error.\nRun `turbot status` to check for known platform issues."
      parse_error_xml(body) || parse_error_json(body) || parse_error_plain(body) || default_error
    end

    def self.parse_error_xml(body)
      xml_errors = REXML::Document.new(body).elements.to_a("//errors/error")
      msg = xml_errors.map { |a| a.text }.join(" / ")
      return msg unless msg.empty?
    rescue Exception
    end

    def self.parse_error_json(body)
      json = JSON.load(body.to_s) rescue false
      case json
      when Array
        json.first.join(' ') # message like [['base', 'message']]
      when Hash
        json['error'] || json['error_message'] || json['message'] # message like {'error' => 'message'}
      else
        nil
      end
    end

    def self.parse_error_plain(body)
      return unless body.respond_to?(:headers) && body.headers[:content_type].to_s.include?("text/plain")
      body.to_s
    end
  end
end
