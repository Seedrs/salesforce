require "spec_helper"

describe SalesforceSync::Resource::Action do
  describe "#upsert" do
    let(:client){ double("client") }
    let(:sf_class){ double("sf_class", sf_type: "sf_type", resource_id_name: "resource_id_name") }
    let(:resource){ double("resource", id: 1234) }
    let(:all_prepared_fields){ { f1: "f1", f2: "f2" } }
    let(:sf_resource){ double("sf_resource", all_prepared_fields: all_prepared_fields, resource: resource) }
    let(:salesforce_id){ "sf_id" }

    before do
      allow_any_instance_of(described_class).to receive(:client).and_return(client)
      allow(sf_class).to receive(:new).and_return(sf_resource)
      allow(client).to receive(:upsert!).with("sf_type", "resource_id_name", all_prepared_fields).and_return(salesforce_id)
      allow(sf_resource).to receive(:store_salesforce_id).with(salesforce_id)
      allow(sf_resource).to receive(:after_upsert)
    end

    context "when the resource is present" do
      it "upserts, stores the salesforce id and call after upsert" do
        described_class.new(sf_class, resource.id).upsert

        expect(client).to have_received(:upsert!).with("sf_type", "resource_id_name", all_prepared_fields)
        expect(sf_resource).to have_received(:store_salesforce_id).with(salesforce_id)
        expect(sf_resource).to have_received(:after_upsert)
      end
    end

    context "when the resource is not present" do
      let(:resource){ nil }

      it "does not upsert the resource, does not store the salesforce id and does not call after upsert" do
        described_class.new(sf_class, 1234).upsert

        expect(client).not_to have_received(:upsert!)
        expect(sf_resource).not_to have_received(:store_salesforce_id)
        expect(sf_resource).not_to have_received(:after_upsert)
      end
    end
  end

  describe "#destroy" do
    let(:client){ double("client") }
    let(:sf_class){ double("sf_class", sf_type: "sf_type") }
    let(:resource){ double("resource", id: 1234) }
    let(:sf_resource){ double("sf_resource", synchronised?: synchronised?, salesforce_id: "sf_id") }
    let(:synchronised?){ true }
    let(:identifiers){ double("identifiers") }

    before do
      allow_any_instance_of(described_class).to receive(:client).and_return(client)
      allow(sf_class).to receive(:new).and_return(sf_resource)
      allow(client).to receive(:destroy).with("sf_type", "sf_id")
      allow(SalesforceSync::Resource::Identifier).to receive(:where).with(salesforce_id: "sf_id").and_return(identifiers)
      allow(identifiers).to receive(:destroy_all)
    end

    context "when the resource is synced on Salesforce" do
      let(:synchronised?){ true }

      it "destroys the resource on Salesforce and remove the Salesforce identifier" do
        described_class.new(sf_class, resource.id).destroy
        expect(client).to have_received(:destroy).with("sf_type", "sf_id")
        expect(identifiers).to have_received(:destroy_all)
      end
    end

    context "when the resource is not synced on Salesforce" do
      let(:synchronised?){ false }

      it "does not destroy the resource on Salesforce nor the Salesforce identifier" do
        described_class.new(sf_class, resource.id).destroy
        expect(client).not_to have_received(:destroy).with("sf_type", "sf_id")
        expect(identifiers).not_to have_received(:destroy_all)
      end
    end
  end

  describe "#get" do
    let(:client){ double("client") }
    let(:sf_class){ double("sf_class", sf_type: "sf_type") }
    let(:resource){ double("resource", id: 1234) }
    let(:sf_resource){ double("sf_resource", synchronised?: synchronised?, salesforce_id: "sf_id") }
    let(:synchronised?){ true }
    let(:identifiers){ double("identifiers") }

    before do
      allow_any_instance_of(described_class).to receive(:client).and_return(client)
      allow(sf_class).to receive(:new).and_return(sf_resource)
      allow(client).to receive(:find).with("sf_type", "sf_id")
      allow(SalesforceSync::Resource::Identifier).to receive(:where).with(salesforce_id: "sf_id").and_return(identifiers)
    end

    context "when the resource is synced on Salesforce" do
      let(:synchronised?){ true }

      it "finds the resource on Salesforce" do
        described_class.new(sf_class, resource.id).get
        expect(client).to have_received(:find).with("sf_type", "sf_id")
      end
    end

    context "when the resource is not synced on Salesforce" do
      let(:synchronised?){ false }

      it "does not returns nil" do
        expect(described_class.new(sf_class, resource.id).get).to be_nil
      end
    end
  end

  describe "#select" do
    let(:client){ double("client") }
    let(:query){ "Select Id from Account where Email != null" }

    before do
      allow_any_instance_of(described_class).to receive(:client).and_return(client)
      allow(client).to receive(:query).with(query).and_return(collection)
    end

    context "when the query returns some elements" do
      let(:collection){ [{ a: 1 }, { a: 2 }] }

      it "returns the elements" do
        elements = described_class.select(query)
        expect(elements).to eq(collection)
      end
    end

    context "when the query returns nothing" do
      let(:collection){ [] }

      it "returns an empty array" do
        elements = described_class.select(query)
        expect(elements).to eq([])
      end
    end
  end

  describe "#publish_event" do
    let(:client) { double("client") }
    let(:event_name) { "custom_event" }
    let(:payload) { { "custom_fieldA" => "Custom field A", "custom_fieldB" => "Custom field B" } }

    before do
      response = double("response")
      allow(response).to receive(:body).and_return(::Restforce::Mash.new)
      allow(client).to receive(:api_post).and_return(response)
      allow(Restforce).to receive(:new).and_return(client)
    end

    it "calls api_post on Restforce client" do
      described_class.publish_event(event_name, payload)
      expect(client).to have_received(:api_post).with("sobjects/#{event_name}", payload)
    end
  end
end
