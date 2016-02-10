module Turbot
  module Helpers
    extend self

    def ask
      STDIN.gets.to_s.strip
    end

    def ask_for_password_on_windows
      require 'Win32API'

      password = ''

      while char = Win32API.new('crtdll', '_getch', [], 'L').Call do
        if char == 10 || char == 13 # received carriage return or newline
          break
        end
        if char == 127 || char == 8 # backspace and delete
          password.slice!(-1, 1)
        else
          # windows might throw a -1 at us so make sure to handle RangeError
          (password << char.chr) rescue RangeError
        end
      end

      password
    end

    def ask_for_password
      system 'stty -echo'
      password = ask
      system 'stty echo'
      password
    end
  end
end
