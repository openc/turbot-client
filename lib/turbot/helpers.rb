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

    def display(msg = '', new_line = true)
      if new_line
        puts(msg)
      else
        print(msg)
      end
      $stdout.flush
    end

    def ask
      $stdin.gets.to_s.strip
    end

    ## DISPLAY HELPERS

    def error(message)
      prefix = ' !    '
      $stderr.puts(prefix + message.split("\n").join("\n#{prefix}"))
      exit(1)
    end

    # produces a printf formatter line for an array of items
    # if an individual line item is an array, it will create columns
    # that are lined-up
    #
    # line_formatter(["foo", "barbaz"])                 # => "%-6s"
    # line_formatter(["foo", "barbaz"], ["bar", "qux"]) # => "%-3s   %-6s"
    #
    def line_formatter(array)
      if array.any? {|item| item.is_a?(Array)}
        cols = []
        array.each do |item|
          if item.is_a?(Array)
            item.each_with_index { |val,idx| cols[idx] = [cols[idx]||0, (val || '').length].max }
          end
        end
        cols.map { |col| "%-#{col}s" }.join("  ")
      else
        "%s"
      end
    end

    def styled_array(array, options = {})
      fmt = line_formatter(array)
      array = array.sort unless options[:sort] == false
      array.each do |element|
        display((fmt % element).rstrip)
      end
      display
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
      formatted_error << "    Version:     #{Turbot.user_agent}"
      formatted_error << "\n"
      formatted_error.join("\n")
    end

    def styled_error(error, message = 'Turbot client internal error.')
      $stderr.puts(format_error(error, message))
    end

    def styled_header(header)
      display("=== #{header}")
    end

    def styled_hash(hash, keys = nil)
      max_key_length = hash.keys.map {|key| key.to_s.length}.max.to_i + 2
      keys ||= hash.keys.sort {|x,y| x.to_s <=> y.to_s}
      keys.each do |key|
        case value = hash[key]
        when Array
          if value.empty?
            next
          else
            elements = value.sort {|x,y| x.to_s <=> y.to_s}
            display("#{key}: ".ljust(max_key_length), false)
            display(elements[0])
            elements[1..-1].each do |element|
              display("#{' ' * max_key_length}#{element}")
            end
            if elements.length > 1
              display
            end
          end
        when nil
          next
        else
          display("#{key}: ".ljust(max_key_length), false)
          display(value)
        end
      end
    end
  end
end
