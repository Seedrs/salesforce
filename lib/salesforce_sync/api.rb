module SalesforceSync
  class Api
    # Trigger the upsert of a resource to be performed now
    def self.resource_synchronisation(resource)
      SalesforceSync::Resource::QueueItem.new(resource).push_upsert(true)
    end

    # Returns a hash of the resource on Salesforce
    def self.get(resource)
      sf_class = SalesforceSync::Resource::Factory.sf_class(resource.class)
      SalesforceSync::Resource::Action.new(sf_class, resource).get
    end

    # Select query on Salesforce
    def self.select(query)
      SalesforceSync::Resource::Action.select(query)
    end

    # Trigger the upsert of a group of resources
    def self.bulk_synchronisation(ids_by_class)
      SalesforceSync::Bulk::Action.new(ids_by_class: ids_by_class).synchronise
    end

    # Figure out if a resource is synced with Salesforce
    def self.synchronised?(resource)
      sf_resource = SalesforceSync::Resource::Factory.create(resource)
      sf_resource.synchronised?
    end

    # Returns the Salesforce id of the resource
    def self.salesforce_id(resource)
      sf_resource = SalesforceSync::Resource::Factory.create(resource)
      sf_resource.salesforce_id
    end

    # Returns the url of the resource on Salesforce
    def self.url(resource)
      sf_resource = SalesforceSync::Resource::Factory.create(resource)
      sf_resource.url
    end

    # Adds a event to the Salesforce EventBus
    # Raises exceptions if an error is returned from Salesforce
    # Returns true on success
    def self.publish_event(event_name, payload)
      SalesforceSync::Resource::Action.publish_event(event_name, payload)
    end

    # Synchronise all existing resources to Salesforce
    # Be carreful: it destroys all existing Salesforce ids
    # Useful in test environment to fill the records of a Sandbox
    def self.platform_reset
      platform_ids_by_class = SalesforceSync.config.resources_by_class.keys.each_with_object(Hash.new{ |h, k| h[k] = [] }) do |klass, ids|
        ids[klass] = klass.pluck(:id)
      end

      SalesforceSync::Resource::Identifier.destroy_all
      bulk_synchronisation(platform_ids_by_class)
    end
  end
end
