require "spec_helper"

describe SalesforceSync::Bulk::Request do
  describe "#process_requests" do
    let(:resource_class){ double("resource_class") }
    let(:sf_class){ double("sf_class", resource_class: resource_class) }
    let(:number_of_objects){ 2 }
    let(:resource_ids){ Array.new(number_of_objects){ |i| i } }
    let(:resources){ resource_ids.map{ |id| double("resource_#{id}", id: id) } }
    let(:sf_resources) do
      resources.map do |resource|
        double("sf_object_#{resource.id}", resource_id: resource.id, resource: resource, all_prepared_fields: "sf_fields_#{resource.id}", synchronised?: false)
      end
    end

    let(:salesforce_bulk_api){ double("sf_api").as_null_object }
    let(:salesforce_response){ double("salesforce_response", salesforce_ids: salesforce_ids, successful?: true) }
    let(:salesforce_ids){ Array.new(number_of_objects){ |i| "sf_id_#{i}" } }

    before do
      salesforce_client = double("salesforce_client").as_null_object
      allow(::Restforce).to receive(:new).and_return(salesforce_client)
      allow(SalesforceBulkApi::Api).to receive(:new).with(salesforce_client).and_return(salesforce_bulk_api)

      raw_salesforce_response = double("raw_salesforce_response")
      allow(salesforce_bulk_api).to receive(:upsert).and_return(raw_salesforce_response)
      allow(SalesforceSync::Bulk::Response).to receive(:new).with(raw_salesforce_response).and_return(salesforce_response)

      allow(sf_class.resource_class).to receive_message_chain(:where, :find_each).and_yield(resources[0]).and_yield(resources[1])

      allow(sf_class).to receive(:sf_type).and_return("sf_type")
      allow(sf_class).to receive(:resource_id_name).and_return("resource_id_name")

      sf_resources.each_with_index do |sf_resource, index|
        allow(sf_class).to receive(:new).with(resources[index]).and_return(sf_resource)
        allow(sf_resource).to receive(:store_salesforce_id)
        allow(sf_resource).to receive(:after_upsert)
      end

      allow(SalesforceSync::Resource::Factory).to receive(:resource_class).with(sf_class).and_return(resource_class)
    end

    context "when there are resources to syncronize" do
      it "upserts the resources to Salesforce, store their salesforces ids, call after upsert" do
        expected_fields = Array.new(number_of_objects){ |i| "sf_fields_#{i}" }

        described_class.new(sf_class, resource_ids).process
        expect(salesforce_bulk_api).to have_received(:upsert).with("sf_type", expected_fields, "resource_id_name", true)
        expect(sf_resources).to all(have_received(:store_salesforce_id))
        expect(sf_resources).to all(have_received(:after_upsert))
      end

      context "when salesforce api call raises an error" do
        it "raises a SalesforceSync::Error" do
          allow(salesforce_bulk_api).to receive(:upsert){ raise "salesforce api error" }
          sf_error = double("sf_error")
          allow(SalesforceSync::Error).to receive(:new).and_return(sf_error)
          allow(sf_error).to receive(:raise_error)

          described_class.new(sf_class, resource_ids).process
          expect(sf_error).to have_received(:raise_error)
        end
      end

      context "when Salesforce response contains some error" do
        let(:salesforce_response){ double("salesforce_response", salesforce_ids: salesforce_ids, successful?: false, error_message: "the error message") }

        it "raises a SalesforceSync::Error" do
          sf_error = double("sf_error")
          allow(SalesforceSync::Error).to receive(:new).and_return(sf_error)
          allow(sf_error).to receive(:raise_error).once

          described_class.new(sf_class, resource_ids).process
          expect(sf_error).to have_received(:raise_error)
        end
      end

      context "when the number of resource is higher than the max number of object per request" do
        let(:number_of_objects){ 2 * described_class::MAX_OBJECT_PER_REQUEST + 1 }

        it "runs the synchronisation in batches and finish the process" do
          described_class.new(sf_class, resource_ids).process
          expect(salesforce_bulk_api).to have_received(:upsert).exactly(3).times
        end
      end
    end

    context "when there is no resources to synchronize" do
      let(:number_of_objects){ 0 }

      it "does not call upsert on Salesforce nor store the salesforce ids" do
        described_class.new(sf_class, resource_ids).process

        expect(salesforce_bulk_api).not_to have_received(:upsert)
        sf_resources.each do |sf_resource|
          expect(sf_resource).not_to have_received(:store_salesforce_id)
          expect(sf_resource).not_to have_received(:after_upsert)
        end
      end
    end
  end
end
