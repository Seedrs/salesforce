SalesforceSync.configure do |config|
  # Declare here the mapping between your application resource classes
  # and their coresponding SalesforceSync::Resource::Base child class
  # Default: {}
  # Example: config.resources_by_class = { User => SalesforceSync::Resource::User }
  config.resources_by_class = {}

  # Declare here the list of event that will trigger SalesforceSync upsert or destroy action
  # Default: []
  # Example: config.events = %w(user.create user.destroy)
  config.events = %w()

  # Declare here the lbase url of your Salesforce application
  config.salesforce_url = ""

  # Enable / disable SalesforceSync resource event synchronisations
  # Default: true
  # config.active = false

  # Uncomment this line if you which to notify Airbrake on SalesforceSync errors
  # config.raise_on_airbrake = true

  # Declare here a custom Delayed::Job column used to identify SalesforceSync jobs
  # This column must exist on the Delayed::Job table as a string
  # Default: :queue
  # config.job_identifier_column =

  # Configure the minimum time between the event notification and the job execution
  # Default: 1.minute
  # config.queue_waiting_time =

  # Configure the list of suffix that allow SalesforceSync to figure out the action to trigger on the event notification
  # Default destroy: destroy_event_suffixes = %w(.destroy .destroyed)
  # Default: upsert_event_suffixes = %w(.save .create update .saved .created .updated)
  # config.destroy_event_suffixes =
  # config.upsert_event_suffixes =
end

# Subscribe SalesforceSync to the list of events
SalesforceSync.start
