module SalesforceSync
  module Resource
    class Action
      SF_USER_QUERY_TYPE = "Contact"

      def initialize(sf_class = nil, resource_id = nil)
        @sf_class = sf_class
        @resource_id = resource_id
      end

      def upsert
        raise_missing_record unless sf_resource.resource.present?

        if sf_resource.synchronised? || sf_class.sf_type != SF_USER_QUERY_TYPE
          upsert_record
        else
          query = [
            "select Id from #{SF_USER_QUERY_TYPE}",
            "where email = '#{sf_resource.resource.email}'",
            "AND State__c != 'disabled'"
          ].join(" ")
          result = self.class.select(query)

          case result.size
          when 0
            upsert_record
          when 1
            update_record(result.first)
          else
            message = "#{SF_USER_QUERY_TYPE}: #{sf_resource.resource.id}, found duplicates: #{result.collect{|r| r[:Id]}}"
            SalesforceSync::Error.new(message, self.class).raise_error
          end
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

      def self.publish_event(event_name, payload)
        new.send("client").api_post("sobjects/#{event_name}", payload).body.success
      end

      private

      attr_reader :sf_class, :resource_id, :salesforce_id

      def client
        @@client ||= ::Restforce.new(api_version: SalesforceSync.config.api_version)
      end

      def sf_resource
        @sf_resource ||= sf_class.new(resource_id)
      end

      def upsert_record
        salesforce_id = client.upsert!(sf_class.sf_type, sf_class.resource_id_name, sf_resource.all_prepared_fields)
        sf_resource.store_salesforce_id(salesforce_id)
        sf_resource.after_upsert
      end

      def update_record(data)
        params = sf_resource.all_prepared_fields.merge(Id: data[:Id])
        client.update!("#{SF_USER_QUERY_TYPE}", params)
        sf_resource.store_salesforce_id(data[:Id])
      end

      def raise_missing_record
        SalesforceSync::Error.new("Missing record: #{@sf_class.sf_type}", self.class).raise_error
      end
    end
  end
end
