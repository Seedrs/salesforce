module SalesforceSync
  module Resource
    class Identifier < ::ActiveRecord::Base
      self.table_name = "salesforce_identifiers"
    end
  end
end
