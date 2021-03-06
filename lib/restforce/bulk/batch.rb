module Restforce
  module Bulk
    class Batch
      include Restforce::Bulk::Attributes

      class << self
        def create(job_id, data, operation, content_type=:json)
          builder  = builder_class_for(content_type).new(operation)

          response = Restforce::Bulk.client.perform_request(:post, "job/#{job_id}/batch", builder.transform(data, operation, content_type), content_type)

          new(response.body)
        end

        def find(job_id, id)
          new(job_id: job_id, id: id).tap(&:refresh)
        end

        def builder_class_for(content_type)
          Restforce::Bulk::Builder.const_get(content_type.to_s.camelize)
        end
      end

      attr_accessor :id, :job_id, :state, :created_date, :system_modstamp, :number_records_processed

      def initialize(attributes={})
        assign_attributes(attributes)
      end

      def queued?
        state == 'Queued'
      end

      def in_progress?
        state == 'InProgress'
      end

      def completed?
        state == 'Completed'
      end

      def failed?
        state == 'Failed'
      end

      def not_processed?
        state == 'Not Processed'
      end

      def refresh
        response = Restforce::Bulk.client.perform_request(:get, "job/#{job_id}/batch/#{id}")

        assign_attributes(response.body)
      end

      def results
        response = Restforce::Bulk.client.perform_request(:get, "job/#{job_id}/batch/#{id}/result")
        parser   = results_parser_for(response.body).new

        parser.results_on(response.body).map do |id|
          Restforce::Bulk::Result.new({job_id: job_id, batch_id: id, id: id})
        end
      end

      protected

      def results_parser_for(body)
        body.is_a?(CSV::Table) ? Restforce::Bulk::Parser::Csv : Restforce::Bulk::Parser::Json
      end
    end
  end
end
