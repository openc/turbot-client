# Turbot CLI

[![Gem Version](https://badge.fury.io/rb/turbot.svg)](https://badge.fury.io/rb/turbot)
[![Build Status](https://secure.travis-ci.org/openc/turbot-client.png)](https://travis-ci.org/openc/turbot-client)
[![Dependency Status](https://gemnasium.com/openc/turbot-client.png)](https://gemnasium.com/openc/turbot-client)
[![Coverage Status](https://coveralls.io/repos/openc/turbot-client/badge.png)](https://coveralls.io/r/openc/turbot-client)
[![Code Climate](https://codeclimate.com/github/openc/turbot-client.png)](https://codeclimate.com/github/openc/turbot-client)

The Turbot CLI is used to manage Turbot bots from the command line.

## Getting Started

    gem install turbot

You now have access to the `turbot` command.  Log in using your Turbot account's email and password:

    $ turbot login
    Enter your Turbot credentials.
    Email: email@example.com
    Password (typing will be hidden):

## Development

If you're working on the CLI and you can smoke-test your changes:

    bundle exec turbot

If you need to do this from a different folder, try:

    alias tb="ReleasingBENV_GEMSETS=.gems TURBOT_HOST=http://localhost:3000 RBENV_VERSION=[version] BUNDLE_GEMFILE=/path/to/turbot-client/Gemfile bundle exec turbot"

## Releasing a new version

Bump the version in `lib/turbot/version.rb` according to the [Semantic Versioning](http://semver.org/) convention, then:

    git commit lib/turbot/version.rb -m 'Release new version'
    rake release # requires Rubygems credentials

Based on the [Heroku CLI](https://github.com/heroku/heroku).

Copyright (c) 2015 Chrinon Ltd, released under the MIT license
