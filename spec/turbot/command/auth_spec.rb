require 'spec_helper'
require 'turbot/command/auth'

describe Turbot::Command::Auth do
  describe 'auth' do
    it 'displays help for auth commands' do
      stderr, stdout = execute('auth')

      expect(stderr).to eq('')
      expect(stdout).to include('turbot auth')
      expect(stdout).to include('Additional commands')
      expect(stdout).to include('auth:whoami')
    end
  end

  context 'when editing the .netrc file' do
    before do
      allow(Netrc).to receive(:default_path).and_return(fixture('writable'))
    end

    describe 'auth:login' do
      it 'logs the user in' do
        stub_request(:get, 'http://turbot.opencorporates.com/api/user/api_key?api_key=&email=email@example.com&password=password').to_return({
          :status => 200,
          :body => JSON.dump('api_key' => 'apikey01'),
        })
        stub_request(:get, 'http://turbot.opencorporates.com/api/user?api_key=apikey01').to_return({
          :status => 200,
          :body => JSON.dump('api_key' => 'apikey01'),
        })
        allow($stdin).to receive(:gets).and_return('email@example.com', 'password')
        allow_any_instance_of(Turbot::Command::Auth).to receive(:ask_for_password_on_windows).and_return('password')

        spec_delete_netrc_entry

        stderr, stdout = execute('auth:login')

        expect(spec_read_netrc.to_a).to eq(['email@example.com', 'apikey01'])

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT
Enter your Turbot email and password.
Email: Password (typing will be hidden): 
Authentication successful.
STDOUT
      end

      it 'displays an error message' do
        stub_request(:get, 'http://turbot.opencorporates.com/api/user/api_key?api_key=&email=&password=').to_return(:status => 200, :body => '{"api_key":""}')
        allow($stdin).to receive(:gets).and_return('', '')
        allow_any_instance_of(Turbot::Command::Auth).to receive(:ask_for_password_on_windows).and_return('')

        spec_delete_netrc_entry

        stderr, stdout = execute('auth:login')

        expect(spec_read_netrc).to eq(nil)

        expect(stdout).to eq <<-STDOUT
Enter your Turbot email and password.
Email: Password (typing will be hidden): 
STDOUT
        expect(stderr).to eq <<-STDERR
 !    Authentication failed.
STDERR
      end
    end

    describe 'auth:logout' do
      it 'logs the user out' do
        spec_save_netrc_entry(['user', 'pass'])

        stderr, stdout = execute('auth:logout')

        expect(spec_read_netrc).to eq(nil)

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT
Deleted Turbot credentials.
STDOUT
      end
    end
  end

  context 'when logged in' do
    before do
      allow(Netrc).to receive(:default_path).and_return(fixture('netrc'))
    end

    describe 'auth:token' do
      it "displays the user's api key" do
        stderr, stdout = execute('auth:token')

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT
apikey01
STDOUT
      end
    end

    describe 'auth:whoami' do
      it "displays the user's email address" do
        stderr, stdout = execute('auth:whoami')

        expect(stderr).to eq('')
        expect(stdout).to eq <<-STDOUT
email@example.com
STDOUT
      end
    end

    context 'with TURBOT_HOST set' do
      around(:each) do |example|
        ENV['TURBOT_HOST'] = 'http://turbot.example.com'
        example.run
        ENV['TURBOT_HOST'] = nil
      end

      describe 'auth:token' do
        it "displays the user's api key" do
          stderr, stdout = execute('auth:token')

          expect(stderr).to eq('')
          expect(stdout).to eq <<-STDOUT
apikey02
STDOUT
        end
      end

      describe 'auth:whoami' do
        it "displays the user's email address" do
          stderr, stdout = execute('auth:whoami')

          expect(stderr).to eq('')
          expect(stdout).to eq <<-STDOUT
example@email.com
STDOUT
        end
      end
    end

    context 'with TURBOT_API_KEY set' do
      around(:each) do |example|
        ENV['TURBOT_API_KEY'] = 'apikey99'
        example.run
        ENV['TURBOT_API_KEY'] = nil
      end

      describe 'auth:token' do
        it "displays the user's api key" do
          stderr, stdout = execute('auth:token')

          expect(stderr).to eq('')
          expect(stdout).to eq <<-STDOUT
apikey99
STDOUT
        end
      end

      describe 'auth:whoami' do
        it "displays nothing" do
          stderr, stdout = execute('auth:whoami')

          expect(stderr).to eq('')
          expect(stdout).to eq <<-STDOUT

STDOUT
        end
      end
    end
  end

  context 'when logged out' do
    ['empty', 'nonexistent'].each do |path|
      before do
        allow(Netrc).to receive(:default_path).and_return(fixture(path))
      end

      describe 'auth:token' do
        it 'displays an error message' do
          stderr, stdout = execute('auth:token')

          expect(stdout).to eq('')
          expect(stderr).to eq <<-STDERR
 !    not logged in
STDERR
        end
      end

      describe 'auth:whoami' do
        it 'displays an error message' do
          stderr, stdout = execute('auth:whoami')

          expect(stdout).to eq('')
          expect(stderr).to eq <<-STDERR
 !    not logged in
STDERR
        end
      end
    end
  end

  context 'with a bad .netrc file' do
    before do
      allow(Netrc).to receive(:default_path).and_return(fixture('bad_permissions', 0644))
    end

    describe 'auth:whoami' do
      it 'displays an error message' do
        stderr, stdout = execute('auth:whoami')

        expect(stdout).to eq('')
        expect(stderr).to match(%r{\A !    Permission bits for '.+/spec/fixtures/bad_permissions' should be 0600, but are 644\n\z})
      end
    end
  end
end
