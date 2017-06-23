module SalesforceSync
  module Bulk
    class Response
      attr_reader :response

      def initialize(response)
        @response = response
      end

      def successful?
        successes = results.flat_map do |result|
          result["success"]
        end

        successes.map{ |s| s == "true" }.all?
      end

      def error_message
        "Salesforce bulk api request error, investigate #{job_url}"
      end

      def salesforce_ids
        results.flat_map{ |result| result["id"] }
      end

      private

      def results
        @results ||= begin
          response["batches"].flat_map do |batch|
            batch["response"]
          end
        end
      end

      def job_id
        response["id"].first
      end

      def job_url
        if SalesforceSync.config.salesforce_url.present?
          "#{SalesforceSync.config.salesforce_url}/#{job_id}"
        else
          SalesforceSync::Error.new("Salesforce url should be configured to obtain a bulk job url.", self.class).raise_error
        end
      end
    end
  end
end
