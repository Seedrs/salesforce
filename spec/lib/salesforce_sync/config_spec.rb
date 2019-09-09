require "spec_helper"

describe SalesforceSync::Config do
  subject{ SalesforceSync::Config.new }

  it "has the expected default attributes" do
    expected_default_attributes = {
      resources_by_class: {},
      events: [],
      active: true,
      raise_on_airbrake: false,
      job_identifier_column: :queue,
      api_version: "44.0",
      salesforce_url: "",
      queue_waiting_time: 1.minute,
      destroy_event_suffixes: %w(.destroy .destroyed),
      upsert_event_suffixes: %w(.save .create update .saved .created .updated)
    }

    is_expected.to have_attributes(expected_default_attributes)
  end
end
