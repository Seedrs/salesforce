module SalesforceSync
  module Resource
    class QueueItem
      def initialize(resource)
        @resource = resource
      end

      def push_upsert(run_now = false)
        pull_upsert if run_now && upsert_in_queue?(false)

        unless upsert_in_queue?(run_now)
          action.delay(upsert_job_params(run_now)).upsert
        end
      end

      def pull_upsert
        condition = "#{job_identifier_column} = ? OR #{job_identifier_column} = ?"
        Delayed::Job.where(condition, job_identifier_name(true), job_identifier_name(false)).destroy_all
      end

      def push_destroy
        action.delay.destroy
      end

      private

      attr_reader :resource

      def upsert_in_queue?(run_now)
        Delayed::Job.where(job_identifier_column => job_identifier_name(run_now)).count > 0
      end

      def sf_class
        @sf_class ||= SalesforceSync::Resource::Factory.sf_class(resource.class)
      end

      def job_identifier_name(run_now)
        name = "Sf_Upsert_#{sf_class.to_s.demodulize}_#{resource.id}"
        name += "_now" if run_now
        name
      end

      def upsert_job_params(run_now)
        params = { job_identifier_column => job_identifier_name(run_now) }
        params[:run_at] = waiting_time.from_now unless run_now
        params
      end

      def job_identifier_column
        SalesforceSync.config.job_identifier_column
      end

      def waiting_time
        SalesforceSync.config.queue_waiting_time
      end

      def salesforce_id
        SalesforceSync::Api.salesforce_id(resource)
      end

      def action
        SalesforceSync::Resource::Action.new(sf_class, resource.id)
      end
    end
  end
end
