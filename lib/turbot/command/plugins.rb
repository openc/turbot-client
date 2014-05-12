require "turbot/command/base"

module Turbot::Command

  # manage plugins to the turbot gem
  class Plugins < Base

    # plugins
    #
    # list installed plugins
    #
    #Example:
    #
    # $ turbot plugins
    # === Installed Plugins
    # turbot-accounts
    #
    def index
      validate_arguments!

      plugins = ::Turbot::Plugin.list

      if plugins.length > 0
        styled_header("Installed Plugins")
        styled_array(plugins)
      else
        display("You have no installed plugins.")
      end
    end

    # plugins:install URL
    #
    # install a plugin
    #
    #Example:
    #
    # $ turbot plugins:install https://github.com/ddollar/turbot-accounts.git
    # Installing turbot-accounts... done
    #
    def install
      plugin = Turbot::Plugin.new(shift_argument)
      validate_arguments!

      action("Installing #{plugin.name}") do
        if plugin.install
          unless Turbot::Plugin.load_plugin(plugin.name)
            plugin.uninstall
            exit(1)
          end
        else
          error("Could not install #{plugin.name}. Please check the URL and try again.")
        end
      end
    end

    # plugins:uninstall PLUGIN
    #
    # uninstall a plugin
    #
    #Example:
    #
    # $ turbot plugins:uninstall turbot-accounts
    # Uninstalling turbot-accounts... done
    #
    def uninstall
      plugin = Turbot::Plugin.new(shift_argument)
      validate_arguments!

      action("Uninstalling #{plugin.name}") do
        plugin.uninstall
      end
    end

    # plugins:update [PLUGIN]
    #
    # updates all plugins or a single plugin by name
    #
    #Example:
    #
    # $ turbot plugins:update
    # Updating turbot-accounts... done
    #
    # $ turbot plugins:update turbot-accounts
    # Updating turbot-accounts... done
    #
    def update
      plugins = if plugin = shift_argument
        [plugin]
      else
        ::Turbot::Plugin.list
      end
      validate_arguments!

      plugins.each do |plugin|
        begin
          action("Updating #{plugin}") do
            begin
              Turbot::Plugin.new(plugin).update
            rescue Turbot::Plugin::ErrorUpdatingSymlinkPlugin
              status "skipped symlink"
            end
          end
        rescue SystemExit
          # ignore so that other plugins still update
        end
      end
    end

  end
end
