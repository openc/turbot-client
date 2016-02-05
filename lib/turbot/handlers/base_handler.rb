module Turbot
  module Handlers
    class BaseHandler < TurbotRunner::BaseHandler
      def handle_invalid_record(record, data_type, error_message)
        puts
        puts "The following record is invalid:"
        puts record.to_json
        puts " * #{error_message}"
        puts
      end

      def handle_non_json_output(line)
        puts
        puts "The following line was not valid JSON:"
        puts line
      end
    end
  end
end
