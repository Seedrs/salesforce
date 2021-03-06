require "spec_helper"

describe SalesforceSync::Api do
  describe "#resource_synchronisation" do
    it "calls SalesforceSync::Resource::QueueItem#push_upsert" do
      resource = double("resource")
      queue_item = double("queue_item")
      allow(SalesforceSync::Resource::QueueItem).to receive(:new).with(resource).and_return(queue_item)
      allow(queue_item).to receive(:push_upsert).with(true)

      described_class.resource_synchronisation(resource)
      expect(queue_item).to have_received(:push_upsert).with(true)
    end
  end

  describe "#bulk_synchronisation" do
    it "calls SalesforceSync::Bulk::Action#synchronise" do
      klass = double("klass")
      ids_by_class = { klass => [1, 2] }
      action = double("action")
      allow(SalesforceSync::Bulk::Action).to receive(:new).with(ids_by_class: ids_by_class).and_return(action)
      allow(action).to receive(:synchronise)

      described_class.bulk_synchronisation(ids_by_class)
      expect(action).to have_received(:synchronise)
    end
  end

  describe "#get" do
    it "calls get on the resource action" do
      resource = double("resource", class: "resource_class")
      sf_class = double("sf_class")
      action = double("action")
      allow(SalesforceSync::Resource::Factory).to receive(:sf_class).and_return(sf_class)
      allow(SalesforceSync::Resource::Action).to receive(:new).with(sf_class, resource).and_return(action)
      allow(action).to receive(:get)

      described_class.get(resource)
      expect(action).to have_received(:get)
    end
  end

  describe "#select" do
    it "calls SalesforceSync::Resource::Action#select" do
      query = "query"
      allow(SalesforceSync::Resource::Action).to receive(:select).with(query)

      described_class.select(query)
      expect(SalesforceSync::Resource::Action).to have_received(:select).with(query)
    end
  end

  describe "#synchronised?" do
    it "calls synchronised? on the sf_resource" do
      resource = double("resource")
      sf_resource = double("sf_resource")
      allow(SalesforceSync::Resource::Factory).to receive(:create).and_return(sf_resource)
      allow(sf_resource).to receive(:synchronised?)

      described_class.synchronised?(resource)
      expect(sf_resource).to have_received(:synchronised?)
    end
  end

  describe "#salesforce_id" do
    it "calls salesforce_id on the sf_resource" do
      resource = double("resource")
      sf_resource = double("sf_resource")
      allow(SalesforceSync::Resource::Factory).to receive(:create).and_return(sf_resource)
      allow(sf_resource).to receive(:salesforce_id)

      described_class.salesforce_id(resource)
      expect(sf_resource).to have_received(:salesforce_id)
    end
  end

  describe "#url" do
    it "calls url on the sf_resource" do
      resource = double("resource")
      sf_resource = double("sf_resource")
      allow(SalesforceSync::Resource::Factory).to receive(:create).and_return(sf_resource)
      allow(sf_resource).to receive(:url)

      described_class.url(resource)
      expect(sf_resource).to have_received(:url)
    end
  end

  describe "#publish_event" do
    let(:event_name) { "custom_event" }
    let(:payload) { { "custom_fieldA" => "Custom field A", "custom_fieldB" => "Custom field B" } }

    before do
      allow(SalesforceSync::Resource::Action).to receive(:publish_event).with(event_name, payload)
    end
    it "calls SalesforceSync::Resource::Action#publish_event" do
      described_class.publish_event(event_name, payload)
      expect(SalesforceSync::Resource::Action).to have_received(:publish_event).with(event_name, payload)
    end
  end

  describe "#platform_reset" do
    it "destroys all identifier and bulk synchronise all resources" do
      resource_ids = [1, 2, 3, 4]
      klass = double("klass", pluck: resource_ids)
      resources_by_class = { klass => double("sf_class") }
      config = double("config", resources_by_class: resources_by_class)
      allow(SalesforceSync).to receive(:config).and_return(config)
      allow(SalesforceSync::Resource::Identifier).to receive(:destroy_all)
      allow(described_class).to receive(:bulk_synchronisation).with(klass => resource_ids)

      described_class.platform_reset
      expect(SalesforceSync::Resource::Identifier).to have_received(:destroy_all)
      expect(described_class).to have_received(:bulk_synchronisation).with(klass => resource_ids)
    end
  end
end
