module Turbot
  module Handlers
    class PreviewHandler < BaseHandler
      attr_reader :count

      def initialize(bot_name, api)
        @bot_name = bot_name
        @api = api
        @batch = []
        @count = 0
        super()
      end

      def handle_valid_record(record, data_type)
        @count += 1
        STDOUT.write('.')
        @batch << record.merge(:data_type => data_type)
        submit_batch if @count % 20 == 0
      end

      def submit_batch
        result = @api.create_draft_data(@bot_name, @batch.to_json)
        @batch = []
        result
      end
    end
  end
end
