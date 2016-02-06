class Turbot::CLI
  extend Turbot::Helpers

  def self.start(*args)
    begin
      if $stdin.isatty
        $stdin.sync = true
      end
      if $stdout.isatty
        $stdout.sync = true
      end
      command = args.shift.strip rescue 'help'
      Turbot::Command.load
      trap 'SIGINT' do
        # Script terminated by Control-C.
        exit 130
      end
      Turbot::Command.run(command, args)
    rescue Interrupt
      `stty icanon echo`
      error('Command cancelled.')
    rescue => error
      styled_error(error)
      exit(1)
    end
  end
end
