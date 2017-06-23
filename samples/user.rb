module SalesforceResource
  class User < SalesforceSync::Resource::Base
    def self.sf_type
      "Contact"
    end

    def self.resource_id_name
      "User_ID__c"
    end

    def require_upsert?(_event = nil, _changed_attributes = {})
      resource.email.present?
    end

    def all_fields
      {
        User_ID__c: resource.id,
        FirstName: resource.first_name,
        LastName: resource.last_name,
        Email: resource.last_name,
        Phone: resource.telephone
      }
    end
  end
end
