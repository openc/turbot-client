module Turbot
  module Helpers
    DEFAULT_HOST = 'http://turbot.opencorporates.com'

    extend self

    # Returns the base URL of the Turbot server.
    #
    # @return [String] the base URL of the Turbot server
    def host
      ENV['TURBOT_HOST'] || DEFAULT_HOST
    end

    def error(message)
      prefix = ' !    '
      STDERR.puts(prefix + message.split("\n").join("\n#{prefix}"))
      exit(1)
    end

    def styled_error(error, message = 'Turbot client internal error.')
      STDERR.puts(format_error(error, message))
    end

    def format_error(error, message = 'Turbot client internal error.')
      formatted_error = []
      formatted_error << " !    #{message}"
      formatted_error << ' !    Report a bug at: https://github.com/openc/turbot-client/issues/new'
      formatted_error << ''
      formatted_error << "    Error:       #{error.message} (#{error.class})"
      formatted_error << "    Backtrace:   #{error.backtrace.first}"
      error.backtrace[1..-1].each do |line|
        formatted_error << "                 #{line}"
      end
      if error.backtrace.length > 1
        formatted_error << ''
      end
      command = ARGV.map do |arg|
        if arg.include?(' ')
          arg = %{"#{arg}"}
        else
          arg
        end
      end.join(' ')
      formatted_error << "    Command:     turbot #{command}"
      unless host == DEFAULT_HOST
        formatted_error << "    Host:        #{host}"
      end
      formatted_error << "    Version:     #{Turbot::DEBUG_VERSION}"
      formatted_error << "\n"
      formatted_error.join("\n")
    end
  end
end
