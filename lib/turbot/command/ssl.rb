require "turbot/command/base"

module Turbot::Command

  # DEPRECATED: see `turbot certs` instead
  #
  # manage ssl certificates for an bot
  #
  class Ssl < Base

    # ssl
    #
    # list legacy certificates for an bot
    #
    def index
      api.get_domains(bot).body.each do |domain|
        if cert = domain['cert']
          display "#{domain['domain']} has a SSL certificate registered to #{cert['subject']} which expires on #{format_date(cert['expires_at'])}"
        else
          display "#{domain['domain']} has no certificate"
        end
      end
    end

    # ssl:add PEM KEY
    #
    # DEPRECATED: see `turbot certs:add` instead
    #
    def add
      $stderr.puts " !    `turbot ssl:add` has been deprecated. Please use the SSL Endpoint add-on and the `turbot certs` commands instead."
      $stderr.puts " !    SSL Endpoint documentation is available at: https://devcenter.turbot.com/articles/ssl-endpoint"
    end

    # ssl:clear
    #
    # remove legacy ssl certificates from an bot
    #
    def clear
      turbot.clear_ssl(bot)
      display "Cleared certificates for #{bot}"
    end
  end
end
