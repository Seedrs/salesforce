module SalesforceSync
  module Bulk
    class Action
      DELAY_BETWEEN_CHECKS = 30.seconds

      def initialize(ids_by_class: {}, queue_items: nil)
        @queue_items = begin
          if !queue_items.nil?
            queue_items
          else
            requests = requests_from_ids_by_class(ids_by_class)
            requests.map{ |request| QueueItem.new(request) }
          end
        end
      end

      def synchronise
        return if queue_items.nil? || queue_items.empty?

        queue_items.reject!(&:finished?)

        processing_item = queue_items.find(&:processing?)
        unless processing_item.present?
          next_item = queue_items.find{ |request| !request.started? }
          next_item.start if next_item.present?
        end

        unless queue_items.map(&:started?).all?
          self.class.new(queue_items: queue_items).delay(run_at: Time.current + DELAY_BETWEEN_CHECKS).synchronise
        end
      end

      private

      attr_reader :queue_items

      def requests_from_ids_by_class(ids_by_class = {})
        resource_ids = resource_ids_by_sf_class(ids_by_class)

        resources_by_class.values.flat_map do |sf_class|
          ids = resource_ids[sf_class]

          if ids.present?
            batches_resource_ids = ids.each_slice(Request::MAX_OBJECT_PER_REQUEST).to_a

            batches_resource_ids.map do |batch_resource_ids|
              Request.new(sf_class, batch_resource_ids)
            end
          end
        end.compact
      end

      def resource_ids_by_sf_class(ids_by_class)
        resources_by_class.values.each_with_object(Hash.new{ |h, k| h[k] = [] }) do |sf_class, resource_ids|
          ids_by_class.each do |klass, ids|
            if sf_class == SalesforceSync::Resource::Factory.sf_class(klass)
              resource_ids[sf_class] += ids
            end
          end
        end
      end

      def resources_by_class
        SalesforceSync.config.resources_by_class
      end
    end
  end
end
