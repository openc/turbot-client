# Turbot CLI

[![Gem Version](https://badge.fury.io/rb/turbot.svg)](https://badge.fury.io/rb/turbot)
[![Build Status](https://secure.travis-ci.org/openc/turbot-client.png)](https://travis-ci.org/openc/turbot-client)
[![Dependency Status](https://gemnasium.com/openc/turbot-client.png)](https://gemnasium.com/openc/turbot-client)
[![Coverage Status](https://coveralls.io/repos/openc/turbot-client/badge.png)](https://coveralls.io/r/openc/turbot-client)
[![Code Climate](https://codeclimate.com/github/openc/turbot-client.png)](https://codeclimate.com/github/openc/turbot-client)

The Turbot CLI is used to manage Turbot apps from the command line.

## Setup

(Platform-specific installers to follow)

Once installed, you'll have access to the `turbot` command from your command shell.  Log in using the email address and password you used when creating your Turbot account:

    $ turbot login
    Enter your Turbot credentials.
    Email: adam@example.com
    Password:

Press enter at the prompt to upload your existing `SSH` key or create a new one, used for pushing code later on.

## Development

If you're working on the CLI and you can smoke-test your changes:

    $ bundle exec turbot

If you need to do this from a different folder, try:

    alias tb="RBENV_GEMSETS=.gems TURBOT_HOST=http://localhost:3000 RBENV_VERSION=[version] BUNDLE_GEMFILE=/path/to/turbot-client/Gemfile bundle exec turbot"

Copyright (c) 2015 Chrinon Ltd, released under the MIT license
