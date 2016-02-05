module Turbot
  module Handlers
    class DumpHandler < BaseHandler
      def handle_valid_record(record, data_type)
        puts record.to_json
      end
    end
  end
end
