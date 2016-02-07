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
    Enter your Turbot email and password.
    Email: email@example.com
    Password (typing will be hidden):

## Environment variables

* `TURBOT_API_KEY`: Overrides the API key in the `.netrc` file. Allows you to skip authentication.

* `TURBOT_BOT`: Overrides the bot in the current directory or set with the `--bot` option.

* `TURBOT_HOST`: Overrides the base URL of the Turbot server, which is `http://turbot.opencorporates.com` by default.

## Releasing a new version

Bump the version in `lib/turbot/version.rb` according to the [Semantic Versioning](http://semver.org/) convention, then:

    git commit lib/turbot/version.rb -m 'Release new version'
    rake release # requires Rubygems credentials

Based on the [Heroku CLI](https://github.com/heroku/heroku).

Copyright (c) 2015 Chrinon Ltd, released under the MIT license
