module SalesforceSync
  module Resource
    class Action
      def initialize(sf_class = nil, resource_id = nil)
        @sf_class = sf_class
        @resource_id = resource_id
      end

      def upsert
        if sf_resource.resource.present?
          salesforce_id = client.upsert!(sf_class.sf_type, sf_class.resource_id_name, sf_resource.all_prepared_fields)
          sf_resource.store_salesforce_id(salesforce_id)
          sf_resource.after_upsert
        end
      end

      def destroy
        if sf_resource.synchronised?
          client.destroy(sf_class.sf_type, sf_resource.salesforce_id)
          SalesforceSync::Resource::Identifier.where(salesforce_id: sf_resource.salesforce_id).destroy_all
        end
      end

      def get
        if sf_resource.synchronised?
          restforce_object = client.find(sf_class.sf_type, sf_resource.salesforce_id)
          restforce_object.to_hash.deep_symbolize_keys if restforce_object.present?
        end
      end

      def self.select(query)
        collection = new.send("client").query(query)
        return [] if collection.size == 0

        collection.map do |record|
          record.to_hash.deep_symbolize_keys
        end
      end

      private

      attr_reader :sf_class, :resource_id, :salesforce_id

      def client
        @@client ||= ::Restforce.new(api_version: SalesforceSync.config.api_version)
      end

      def sf_resource
        @sf_resource ||= sf_class.new(resource_id)
      end
    end
  end
end
