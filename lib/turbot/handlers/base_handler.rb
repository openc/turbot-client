module Turbot
  module Handlers
    class BaseHandler < TurbotRunner::BaseHandler
      # Implements `TurbotRunner::BaseHandler#handle_invalid_record`.
      def handle_invalid_record(record, data_type, error_message)
        puts
        puts 'The following record is invalid:'
        puts record.to_json
        puts " * #{error_message}"
        puts
      end

      # Implements `TurbotRunner::BaseHandler#handle_invalid_json`.
      def handle_invalid_json(line)
        puts
        puts 'The following line was not valid JSON:'
        puts line
      end
    end
  end
end
