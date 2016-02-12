require 'spec_helper'

describe Turbot::Helpers do
  describe '#styled_error' do
    it 'should display an error' do
      begin
        raise 'My message'
      rescue => e
        original_stderr, original_stdout = $stderr, $stdout

        $stderr = captured_stderr = StringIO.new
        $stdout = captured_stdout = StringIO.new

        Turbot::Helpers.styled_error(e)

        $stderr, $stdout = original_stderr, original_stdout

        [
          ' !    Turbot client internal error.',
          ' !    Report a bug at: https://github.com/openc/turbot-client/issues/new',
          '    Error:       My message (RuntimeError)',
          '    Backtrace:   ',
          '    Command:     ',
          '    Version:     ',
        ].each do |string|
          expect(captured_stderr.string).to include(string)
        end
        expect(captured_stdout.string).to eq('')
      end
    end
  end
end
