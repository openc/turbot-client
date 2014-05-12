require "turbot/command/base"
require "turbot/helpers/log_displayer"

# display logs for an app
#
class Turbot::Command::Logs < Turbot::Command::Base

  # logs
  #
  # display recent log output
  #
  # -n, --num NUM        # the number of lines to display
  # -p, --ps PS          # only display logs from the given process
  # -s, --source SOURCE  # only display logs from the given source
  # -t, --tail           # continually stream logs
  #
  #Example:
  #
  # $ turbot logs
  # 2012-01-01T12:00:00+00:00 turbot[api]: Config add EXAMPLE by email@example.com
  # 2012-01-01T12:00:01+00:00 turbot[api]: Release v1 created by email@example.com
  #
  def index
    validate_arguments!

    opts = []
    opts << "tail=1"                                 if options[:tail]
    opts << "num=#{options[:num]}"                   if options[:num]
    opts << "ps=#{URI.encode(options[:ps])}"         if options[:ps]
    opts << "source=#{URI.encode(options[:source])}" if options[:source]

    log_displayer = ::Turbot::Helpers::LogDisplayer.new(turbot, app, opts)
    log_displayer.display_logs
  end

  # logs:drains
  #
  # DEPRECATED: use `turbot drains`
  #
  def drains
    # deprecation notice added 09/30/2011
    display("~ `turbot logs:drains` has been deprecated and replaced with `turbot drains`")
    Turbot::Command::Drains.new.index
  end
end
