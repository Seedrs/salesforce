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
end
