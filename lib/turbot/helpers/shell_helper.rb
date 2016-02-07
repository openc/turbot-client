module Turbot
  module Helpers
    extend self

    def ask_for_password_on_windows
      require 'Win32API'

      char = nil
      password = ''

      while char = Win32API.new('crtdll', '_getch', [], 'L').Call do
        break if char == 10 || char == 13 # received carriage return or newline
        if char == 127 || char == 8 # backspace and delete
          password.slice!(-1, 1)
        else
          # windows might throw a -1 at us so make sure to handle RangeError
          (password << char.chr) rescue RangeError
        end
      end

      puts
      password
    end

    def ask_for_password
      with_tty do
        system 'stty -echo'
      end

      password = ask

      with_tty do
        system 'stty echo'
      end

      puts
      password
    end

    def with_tty(&block)
      return unless $stdin.isatty
      begin
        yield
      rescue
        # Fails on Windows.
      end
    end
  end
end
