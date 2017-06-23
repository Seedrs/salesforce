module SalesforceSync
  module Bulk
    class Request
      MAX_OBJECT_PER_REQUEST = 1_000

      attr_reader :sf_class, :resource_ids

      def initialize(sf_class, resource_ids)
        @sf_class = sf_class
        @resource_ids = resource_ids
      end

      def process
        batches_resource_ids = resource_ids.each_slice(MAX_OBJECT_PER_REQUEST).to_a
        batches_resource_ids.each{ |batch_resource_ids| process_request(batch_resource_ids) }
      end

      private

      def process_request(batch_resource_ids)
        batch_sf_objects = batch_sf_objects(batch_resource_ids)
        fields = batch_sf_objects.map(&:all_prepared_fields)

        raw_response = salesforce_bulk_api.upsert(sf_type, fields, resource_id_name, true)
        response = Response.new(raw_response)

        store_salesforce_ids(response, batch_sf_objects)
        batch_sf_objects.each(&:after_upsert)

        raise_error(response.error_message) unless response.successful?
      rescue => error
        raise_error(error.message)
      end

      def batch_sf_objects(batch_resource_ids)
        sf_objects.select{ |sf_object| batch_resource_ids.include?(sf_object.resource_id) }
      end

      def sf_objects
        @sf_objects ||= begin
          objects = []
          resource_class.where(id: resource_ids).find_each{ |resource| objects << sf_class.new(resource) }
          objects
        end
      end

      def salesforce_bulk_api
        @salesforce_bulk_api ||= begin
          client = ::Restforce.new(api_version: SalesforceSync.config.api_version)
          client.authenticate!
          ::SalesforceBulkApi::Api.new(client)
        end
      end

      def store_salesforce_ids(response, batch_sf_objects)
        response_salesforce_ids = response.salesforce_ids

        batch_sf_objects.each_with_index do |sf_object, index|
          sf_object.store_salesforce_id(response_salesforce_ids[index]) unless sf_object.synchronised?
        end
      end

      def sf_type
        sf_class.sf_type
      end

      def resource_id_name
        sf_class.resource_id_name
      end

      def resource_class
        SalesforceSync::Resource::Factory.resource_class(sf_class)
      end

      def raise_error(message)
        SalesforceSync::Error.new(message, self.class).raise_error
      end
    end
  end
end
