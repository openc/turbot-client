class Turbot::CLI
  extend Turbot::Helpers

  def self.start(*args)
    begin
      $stdout.sync = true
      $stderr.sync = true

      trap 'SIGINT' do
        # Script terminated by Control-C.
        exit 130
      end

      Turbot::Command.load
      command = args.shift.strip rescue 'help'
      Turbot::Command.run(command, args)
    rescue Interrupt
      `stty icanon echo`
      error 'Command cancelled.'
    rescue => e
      styled_error(e)
      exit(1)
    end
  end
end
