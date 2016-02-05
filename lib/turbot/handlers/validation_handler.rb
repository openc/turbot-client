module Turbot
  module Handlers
    class ValidationHandler < BaseHandler
      attr_reader :count

      def initialize(*)
        @count = 0
        super
      end

      def handle_valid_record(record, data_type)
        @count += 1
        STDOUT.write('.')
      end

      def handle_invalid_record(record, data_type, error_message)
        puts
        puts "The following record is invalid:"
        puts record.to_json
        puts " * #{error_message}"
        puts
      end

      def handle_invalid_json(line)
        puts
        puts "The following line was not valid JSON:"
        puts line
      end
    end
  end
end
