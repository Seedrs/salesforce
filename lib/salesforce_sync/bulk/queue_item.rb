module SalesforceSync
  module Bulk
    class QueueItem
      attr_reader :request
      attr_accessor :status

      def initialize(request)
        @request = request
        @status = :not_started
      end

      def start
        push_to_queue
        self.status = :started
      end

      def started?
        status != :not_started
      end

      def finished?
        started? && !in_queue?
      end

      private

      def push_to_queue
        request.delay(job_identifier_column => job_identifier_name).process
      end

      def in_queue?
        Delayed::Job.where(job_identifier_column => job_identifier_name).count > 0
      end

      def job_identifier_column
        SalesforceSync.config.job_identifier_column
      end

      def job_identifier_name
        "Sf_sync_bulk_#{request.sf_class.to_s.demodulize}"
      end
    end
  end
end
