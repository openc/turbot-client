Turbot CLI
==========

The Turbot CLI is used to manage Turbot apps from the command line.

For more about Turbot see <http://turbot.com>.

To get started see <http://devcenter.turbot.com/articles/quickstart>

[![Build Status](https://secure.travis-ci.org/turbot/turbot.png)](http://travis-ci.org/turbot/turbot)
[![Dependency Status](https://gemnasium.com/turbot/turbot.png)](https://gemnasium.com/turbot/turbot)

Setup
-----

<table>
  <tr>
    <th>If you have...</th>
    <th>Install with...</th>
  </tr>
  <tr>
    <td>Mac OS X</td>
    <td style="text-align: left"><a href="http://toolbelt.turbotapp.com/osx/download">Download OS X package</a></td>
  </tr>
  <tr>
    <td>Windows</td>
    <td style="text-align: left"><a href="http://toolbelt.turbotapp.com/windows/download">Download Windows .exe installer</a></td>
  </tr>
  <tr>
    <td>Ubuntu Linux</td>
    <td style="text-align: left"><a href="http://toolbelt.turbotapp.com/linux/readme"><code>apt-get</code> repository</a></td>
  </tr>
  <tr>
    <td>Other</td>
    <td style="text-align: left"><a href="http://assets.turbot.com/turbot-client/turbot-client.tgz">Tarball</a> (add contents to your <code>$PATH</code>)</td>
  </tr>
</table>

Once installed, you'll have access to the `turbot` command from your command shell.  Log in using the email address and password you used when creating your Turbot account:

    $ turbot login
    Enter your Turbot credentials.
    Email: adam@example.com
    Password:
    Could not find an existing public key.
    Would you like to generate one? [Yn]
    Generating new SSH public key.
    Uploading SSH public key /Users/adam/.ssh/id_rsa.pub

Press enter at the prompt to upload your existing `SSH` key or create a new one, used for pushing code later on.

API
---

For additional information about the API see [Turbot API Quickstart](https://devcenter.turbot.com/articles/platform-api-quickstart) and [Turbot API Reference](https://devcenter.turbot.com/articles/platform-api-reference).

Development
-----------

If you're working on the CLI and you can smoke-test your changes:

    $ bundle exec turbot

Meta
----

Released under the MIT license; see the file License.

Created by Adam Wiggins

[Other Contributors](https://github.com/turbot/turbot/contributors)
