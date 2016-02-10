module CommandHelper
  def execute(command_line)
    original_stderr, original_stdout = $stderr, $stdout

    $stderr = captured_stderr = StringIO.new
    $stdout = captured_stdout = StringIO.new

    begin
      Turbot::CLI.start(*command_line.split(' '))
    rescue Exception => e
      unless SystemExit === e
        p e
      end
    ensure
      $stderr, $stdout = original_stderr, original_stdout
    end

    [captured_stderr.string, captured_stdout.string]
  end
end
