module Turbot
  module Handlers
    class DumpHandler < BaseHandler
      # Implements `TurbotRunner::BaseHandler#handle_valid_record`.
      def handle_valid_record(record, data_type)
        puts record.to_json
      end
    end
  end
end
