module SalesforceSync
  module Resource
    class Event
      attr_reader :resource, :event_name, :changed_attributes

      def initialize(event_name, resource, changed_attributes)
        @resource = resource
        @event_name = event_name
        @changed_attributes = changed_attributes.present? ? changed_attributes.deep_symbolize_keys : nil
      end

      def push
        case event_type
        when :destroy
          push_destroy_event
        when :upsert
          push_upsert_event
        else
          SalesforceSync::Error.new("invalid event name #{event_name}", self.class).raise_error
        end
      end

      private

      def event_type
        @event_type ||= begin
          if event_end_with?(SalesforceSync.config.destroy_event_suffixes)
            :destroy
          elsif event_end_with?(SalesforceSync.config.upsert_event_suffixes)
            :upsert
          end
        end
      end

      def event_end_with?(suffixes)
        suffixes.map{ |suffix| event_name.end_with?(suffix) }.any?
      end

      def push_destroy_event
        queue_item.pull_upsert
        queue_item.push_destroy
      end

      def push_upsert_event
        if sf_resource.require_upsert?(event_name, changed_attributes)
          sf_resource.dependent_resources.each do |dependent_resource|
            if dependent_resource.present? && !SalesforceSync::Api.synchronised?(dependent_resource)
              QueueItem.new(dependent_resource).push_upsert(true)
            end
          end

          queue_item.push_upsert
        end
      end

      def sf_resource
        @sf_resource ||= Factory.create(resource)
      end

      def queue_item
        @queue_item ||= QueueItem.new(resource)
      end
    end
  end
end
