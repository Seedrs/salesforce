module SalesforceSync
  class InitializerGenerator < Rails::Generators::Base
    def create_initializer_file
      create_file "config/initializers/salesforce_sync.rb", File.read("#{File.dirname(__FILE__)}/templates/initializer.rb")
    end
  end
end
