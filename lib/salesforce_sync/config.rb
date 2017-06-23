module SalesforceSync
  class Config
    attr_accessor :resources_by_class
    attr_accessor :events
    attr_accessor :active
    attr_accessor :raise_on_airbrake
    attr_accessor :job_identifier_column
    attr_accessor :api_version
    attr_accessor :salesforce_url
    attr_accessor :queue_waiting_time
    attr_accessor :destroy_event_suffixes
    attr_accessor :upsert_event_suffixes

    def initialize
      @resources_by_class = {}
      @events = []
      @active = true
      @raise_on_airbrake = false
      @job_identifier_column = :queue
      @api_version = "36.0"
      @salesforce_url = ""
      @queue_waiting_time = 1.minute
      @destroy_event_suffixes = %w(.destroy .destroyed)
      @upsert_event_suffixes = %w(.save .create update .saved .created .updated)
    end
  end
end
