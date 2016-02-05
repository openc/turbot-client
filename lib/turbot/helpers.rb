module Turbot
  module Helpers

    extend self

    def running_on_windows?
      RUBY_PLATFORM =~ /mswin32|mingw32/
    end

    def running_on_a_mac?
      RUBY_PLATFORM =~ /-darwin\d/
    end

    def display(msg="", new_line=true)
      if new_line
        puts(msg)
      else
        print(msg)
      end
      $stdout.flush
    end

    def format_date(date)
      date = Time.parse(date).utc if date.is_a?(String)
      date.strftime("%Y-%m-%d %H:%M %Z").gsub('GMT', 'UTC')
    end

    def ask
      $stdin.gets.to_s.strip
    end

    def has_git?
      %x{ git --version }
      $?.success?
    end

    def git(args)
      return "" unless has_git?
      flattened_args = [args].flatten.compact.join(" ")
      %x{ git #{flattened_args} 2>&1 }.strip
    end

    @@kb = 1024
    @@mb = 1024 * @@kb
    @@gb = 1024 * @@mb
    def format_bytes(amount)
      amount = amount.to_i
      return '(empty)' if amount == 0
      return amount if amount < @@kb
      return "#{(amount / @@kb).round}k" if amount < @@mb
      return "#{(amount / @@mb).round}M" if amount < @@gb
      return "#{(amount / @@gb).round}G"
    end

    def longest(items)
      items.map { |i| i.to_s.length }.sort.last
    end

    def with_tty(&block)
      return unless $stdin.isatty
      begin
        yield
      rescue
        # fails on windows
      end
    end

    def fail(message)
      raise Turbot::Command::CommandFailed, message
    end

    ## DISPLAY HELPERS

    def format_with_bang(message)
      return '' if message.to_s.strip == ""
      " !    " + message.split("\n").join("\n !    ")
    end

    def error(message)
      if Turbot::Helpers.error_with_failure
        display("failed")
        Turbot::Helpers.error_with_failure = false
      end
      $stderr.puts(format_with_bang(message))
      exit(1)
    end

    def self.error_with_failure
      @@error_with_failure ||= false
    end

    def self.error_with_failure=(new_error_with_failure)
      @@error_with_failure = new_error_with_failure
    end

    def self.included_into
      @@included_into ||= []
    end

    def self.extended_into
      @@extended_into ||= []
    end

    def self.included(base)
      included_into << base
    end

    def self.extended(base)
      extended_into << base
    end

    def display_header(message="", new_line=true)
      return if message.to_s.strip == ""
      display("=== " + message.to_s.split("\n").join("\n=== "), new_line)
    end

    def hputs(string='')
      Kernel.puts(string)
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

    def styled_array(array, options={})
      fmt = line_formatter(array)
      array = array.sort unless options[:sort] == false
      array.each do |element|
        display((fmt % element).rstrip)
      end
      display
    end

    def format_error(error, message='Turbot client internal error.')
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
      require 'turbot/auth'
      unless Turbot::Auth.host == Turbot::Auth.default_host
        formatted_error << "    Host:        #{Turbot::Auth.host}"
      end
      formatted_error << "    Version:     #{Turbot.user_agent}"
      formatted_error << "\n"
      formatted_error.join("\n")
    end

    def styled_error(error, message='Turbot client internal error.')
      if Turbot::Helpers.error_with_failure
        display("failed")
        Turbot::Helpers.error_with_failure = false
      end
      $stderr.puts(format_error(error, message))
    end

    def styled_header(header)
      display("=== #{header}")
    end

    def styled_hash(hash, keys=nil)
      max_key_length = hash.keys.map {|key| key.to_s.length}.max + 2
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

    def string_distance(first, last)
      distances = [] # 0x0s
      0.upto(first.length) do |index|
        distances << [index] + [0] * last.length
      end
      distances[0] = 0.upto(last.length).to_a
      1.upto(last.length) do |last_index|
        1.upto(first.length) do |first_index|
          first_char = first[first_index - 1, 1]
          last_char = last[last_index - 1, 1]
          if first_char == last_char
            distances[first_index][last_index] = distances[first_index - 1][last_index - 1] # noop
          else
            distances[first_index][last_index] = [
              distances[first_index - 1][last_index],     # deletion
              distances[first_index][last_index - 1],     # insertion
              distances[first_index - 1][last_index - 1]  # substitution
            ].min + 1 # cost
            if first_index > 1 && last_index > 1
              first_previous_char = first[first_index - 2, 1]
              last_previous_char = last[last_index - 2, 1]
              if first_char == last_previous_char && first_previous_char == last_char
                distances[first_index][last_index] = [
                  distances[first_index][last_index],
                  distances[first_index - 2][last_index - 2] + 1 # transposition
                ].min
              end
            end
          end
        end
      end
      distances[first.length][last.length]
    end

    def suggestion(actual, possibilities)
      distances = Hash.new {|hash,key| hash[key] = []}
      possibilities.each do |suggestion|
        distances[string_distance(actual, suggestion)] << suggestion
      end
      minimum_distance = distances.keys.min
      if minimum_distance < 4
        suggestions = distances[minimum_distance].sort
        if suggestions.length == 1
          "Perhaps you meant `#{suggestions.first}`."
        else
          "Perhaps you meant #{suggestions[0...-1].map {|suggestion| "`#{suggestion}`"}.join(', ')} or `#{suggestions.last}`."
        end
      else
        nil
      end
    end
  end
end
