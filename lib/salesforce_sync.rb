require "active_support"
require "delayed_job_active_record"
require "event_bus"
require "restforce"
require "salesforce_bulk_api"

require "salesforce_sync/config"
require "salesforce_sync/api"
require "salesforce_sync/error"

require "salesforce_sync/resource/action"
require "salesforce_sync/resource/event"
require "salesforce_sync/resource/queue_item"
require "salesforce_sync/resource/identifier"
require "salesforce_sync/resource/factory"
require "salesforce_sync/resource/base"

require "salesforce_sync/bulk/action"
require "salesforce_sync/bulk/queue_item"
require "salesforce_sync/bulk/request"
require "salesforce_sync/bulk/response"

module SalesforceSync
  extend self

  attr_reader :config

  def self.configure
    yield(config)
  end

  def self.start
    return unless config.active

    config.events.each do |event_name|
      EventBus.subscribe(event_name) do |payload|
        if payload[:resource].present?
          Resource::Event.new(event_name, payload[:resource], payload[:changed_attributes]).push
        end
      end
    end
  end

  def config
    @config ||= Config.new
  end
end
