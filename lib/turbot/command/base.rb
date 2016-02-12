class Turbot::Command::Base
  include Turbot::Helpers

  def self.namespace
    self.to_s.split('::').last.downcase
  end

  attr_reader :args
  attr_reader :options

  def initialize(args = [], options = {})
    @args = args
    @options = options
  end

  def bot
    @bot ||= if options[:bot].is_a?(String)
      options[:bot]
    elsif ENV['TURBOT_BOT']
      ENV['TURBOT_BOT']
    elsif manifest = parse_manifest
      manifest['bot_id']
    end
  end

protected

  def self.inherited(klass)
    unless klass == Turbot::Command::Base
      help = extract_help_from_caller(caller.first)

      Turbot::Command.register_namespace(
        :name => klass.namespace,
        :description => help.first
      )
    end
  end

  def self.method_added(method)
    if self == Turbot::Command::Base || private_method_defined?(method) || protected_method_defined?(method)
      return
    end

    help = extract_help_from_caller(caller.first)
    resolved_method = (method.to_s == "index") ? nil : method.to_s
    command = [self.namespace, resolved_method].compact.join(":")
    banner = extract_banner(help) || command

    Turbot::Command.register_command(
      :klass       => self,
      :method      => method,
      :namespace   => self.namespace,
      :command     => command,
      :banner      => banner.strip,
      :help        => help.join("\n"),
      :summary     => extract_summary(help),
      :description => extract_description(help),
      :options     => extract_options(help)
    )
  end

  def self.alias_command(command_alias, command)
    Turbot::Command.command_aliases[command_alias] = command
  end

  #
  # Parse the caller format and identify the file and line number as identified
  # in : http://www.ruby-doc.org/core/classes/Kernel.html#M001397.  This will
  # look for a colon followed by a digit as the delimiter.  The biggest
  # complication is windows paths, which have a colon after the drive letter.
  # This regex will match paths as anything from the beginning to a colon
  # directly followed by a number (the line number).
  #
  # Examples of the caller format :
  # * c:/Ruby192/lib/.../lib/turbot/command/addons.rb:8:in `<module:Command>'
  # * c:/Ruby192/lib/.../turbot-2.0.1/lib/turbot/command/pg.rb:96:in `<class:Pg>'
  # * /Users/ph7/...../xray-1.1/lib/xray/thread_dump_signal_handler.rb:9
  #
  def self.extract_help_from_caller(line)
    # pull out of the caller the information for the file path and line number
    if line =~ /^(.+?):(\d+)/
      extract_help($1, $2)
    else
      raise("unable to extract help from caller: #{line}")
    end
  end

  def self.extract_help(file, line_number)
    buffer = []
    lines = Turbot::Command.files[file]

    (line_number.to_i - 2).downto(0) do |i|
      line = lines[i]
      case line[0..0]
        when ""
        when "#"
          buffer.unshift(line[1..-1])
        else
          break
      end
    end

    buffer
  end

  def self.extract_banner(help)
    help.first
  end

  def self.extract_summary(help)
    extract_description(help).split("\n")[2].to_s.split("\n").first
  end

  def self.extract_description(help)
    help.reject do |line|
      line =~ /^\s+-(.+)#(.+)/
    end.join("\n")
  end

  def self.extract_options(help)
    help.select do |line|
      line =~ /^\s+-(.+)#(.+)/
    end.inject([]) do |options, line|
      args = line.split('#', 2).first
      args = args.split(/,\s*/).map {|arg| arg.strip}.sort.reverse
      name = args.last.split(' ', 2).first[2..-1]
      options << { :name => name, :args => args }
    end
  end

  def current_command
    Turbot::Command.current_command
  end

  def validate_arguments!
    Turbot::Command.validate_arguments!
  end

  def parse_manifest
    path = File.join(working_directory, 'manifest.json')
    if File.exists?(path)
      begin
        JSON.load(File.read(path))
      rescue JSON::ParserError => e
        error "`manifest.json` is invalid JSON. Consider validating it at http://pro.jsonlint.com/"
      end
    end
  end

  def working_directory
    Dir.pwd
  end
end
