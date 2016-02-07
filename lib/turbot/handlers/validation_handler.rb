module Turbot
  module Handlers
    class ValidationHandler < BaseHandler
      attr_reader :count

      def initialize
        @count = 0
      end

      # Implements `TurbotRunner::BaseHandler#handle_valid_record`.
      def handle_valid_record(record, data_type)
        @count += 1
        STDOUT.write('.')
      end
    end
  end
end
