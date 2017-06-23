module SalesforceSync
  class Api
    def self.resource_synchronisation(resource)
      SalesforceSync::Resource::QueueItem.new(resource).push_upsert(true)
    end

    def self.bulk_synchronisation(ids_by_class)
      SalesforceSync::Bulk::Action.new(ids_by_class: ids_by_class).synchronise
    end

    def self.synchronised?(resource)
      sf_resource = SalesforceSync::Resource::Factory.create(resource)
      sf_resource.synchronised?
    end

    def self.salesforce_id(resource)
      sf_resource = SalesforceSync::Resource::Factory.create(resource)
      sf_resource.salesforce_id
    end

    def self.url(resource)
      sf_resource = SalesforceSync::Resource::Factory.create(resource)
      sf_resource.url
    end

    def self.platform_reset
      platform_ids_by_class = SalesforceSync.config.resources_by_class.keys.each_with_object(Hash.new{ |h, k| h[k] = [] }) do |klass, ids|
        ids[klass] = klass.pluck(:id)
      end

      SalesforceSync::Resource::Identifier.destroy_all
      bulk_synchronisation(platform_ids_by_class)
    end
  end
end
