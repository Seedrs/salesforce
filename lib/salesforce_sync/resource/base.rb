module SalesforceSync
  module Resource
    class Base
      PROPERTIES_KEYS = %i(sf_type resource_class resource_id_name events)

      def self.properties
        SalesforceSync::Error.new("properties method not implemented", self.class).raise_error
      end

      def self.property(key)
        if properties[key].present?
          properties[key]
        else
          SalesforceSync::Error.new("#{key} property not provided", self.class).raise_error
        end
      end

      # sf_type: the name of the resource on Salesforce side
      def self.sf_type
        property(:sf_type)
      end

      # resource_id_name: the name of the id of the resource on Salesforce side
      def self.resource_id_name
        property(:resource_id_name)
      end

      # resource_class: the class of the resource in the application
      def self.resource_class
        property(:resource_class)
      end

      # events: the list of the events the application should subscribe to
      def self.events
        property(:events)
      end

      # All fields to send to Salesforce
      def all_fields
        SalesforceSync::Error.new("all_fields method not implemented", self.class).raise_error
      end

      # Override this method if you want to force truncating some fields before sending them
      def field_limits
        {}
      end

      # Override this method if upsert needs to be performed only
      # on specific event when specific attributes have been modified.
      # Default behaviour is to always upsert the resource
      def require_upsert?(_event = nil, _changed_attributes = {})
        true
      end

      # List every the resources that need to be upserted before the current resource
      # Default behaviour is no dependent resource
      def dependent_resources
        []
      end

      # Executed after any upsert
      def after_upsert
      end

      def synchronised?
        identifier.salesforce_id.present?
      end

      def salesforce_id
        identifier.salesforce_id if synchronised?
      end

      def url
        if SalesforceSync.config.salesforce_url.present?
          "#{SalesforceSync.config.salesforce_url}/#{salesforce_id}" if synchronised?
        else
          SalesforceSync::Error.new("Salesforce url should be configured to obtain the url of a resource.", self.class).raise_error
        end
      end

      def initialize(resource_or_resource_id)
        if resource_or_resource_id.is_a?(Integer)
          @resource_id = resource_or_resource_id
        else
          @resource = resource_or_resource_id
          @resource_id = resource_or_resource_id.id
        end

        identifier_params = { salesforce_type: self.class.sf_type, resource_id: resource_id }
        @identifier = begin
          if Identifier.where(identifier_params).count > 0
            Identifier.where(identifier_params).first
          else
            Identifier.new(identifier_params)
          end
        end
      end

      attr_reader :resource_id, :identifier

      def resource
        @resource ||= self.class.resource_class.find_by_id(resource_id)
      end

      def all_prepared_fields
        all_fields.each_with_object({}) do |(field_name, field_value), prepared_fields|
          prepared_fields[field_name] = begin
            if field_limits.key?(field_name) && field_limits[field_name] != 0 && field_value.to_s.length > field_limits[field_name]
              options = {}
              options[:omission] = "" if field_value.is_a?(Numeric)
              field_value.to_s.truncate(field_limits[field_name], options)
            else
              field_value
            end
          end
        end
      end

      def store_salesforce_id(salesforce_id)
        if salesforce_id && salesforce_id.is_a?(String)
          identifier.salesforce_id = salesforce_id
          identifier.save!
        end
      end
    end
  end
end
