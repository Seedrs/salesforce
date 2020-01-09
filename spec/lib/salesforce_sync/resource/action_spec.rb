require "spec_helper"

describe SalesforceSync::Resource::Action do
  describe "#upsert" do
    let(:client){ double("client") }
    let(:sf_type){ "sf_type" }
    let(:sf_class){ double("sf_class", sf_type: sf_type, resource_id_name: "resource_id_name") }
    let(:resource){ double("resource", id: 1234, email: "joe@bloggs.com") }
    let(:all_prepared_fields){ { f1: "f1", f2: "f2" } }
    let(:sf_resource){ double("sf_resource", all_prepared_fields: all_prepared_fields, resource: resource) }
    let(:salesforce_id){ "sf_id" }
    let(:sf_record){ double("sf_record") }
    let(:synchronised?){ true }
    let(:query){ "query" }
    let(:collection){ [] }

    before do
      allow_any_instance_of(described_class).to receive(:client).and_return(client)
      allow(sf_class).to receive(:new).and_return(sf_resource)
      allow(client).to receive(:upsert!).with(sf_type, "resource_id_name", all_prepared_fields).and_return(salesforce_id)
      allow(sf_resource).to receive(:store_salesforce_id).with(salesforce_id)
      allow(sf_resource).to receive(:after_upsert)
      allow(sf_resource).to receive(:synchronised?).and_return(synchronised?)
      allow(described_class).to receive(:select).with(query).and_return(collection)
      allow(sf_record).to receive(:[]).with(:Id).and_return(salesforce_id)
    end

    context "when the resource is present" do
      context "when synchronised (has identifier)" do
        it "upserts, stores the salesforce id and call after upsert" do
          described_class.new(sf_class, resource.id).upsert

          expect(client).to have_received(:upsert!).with("sf_type", "resource_id_name", all_prepared_fields)
          expect(sf_resource).to have_received(:store_salesforce_id).with(salesforce_id)
          expect(sf_resource).to have_received(:after_upsert)
        end
      end

      context "when not synchronised (has no identifier)" do
        let(:synchronised?){ false }

        context "when it is not a User" do
          let(:sf_type){ "Account" }

          it "upserts, stores the salesforce id and call after upsert" do
            described_class.new(sf_class, resource.id).upsert

            expect(client).to have_received(:upsert!).with(sf_type, "resource_id_name", all_prepared_fields)
            expect(sf_resource).to have_received(:store_salesforce_id).with(salesforce_id)
            expect(sf_resource).to have_received(:after_upsert)
          end
        end

        context "when it is a User (Contact)" do
          let(:sf_type){ "#{described_class::SF_USER_QUERY_TYPE}" }
          let(:query){ "select Id from #{sf_type} where email = '#{sf_resource.resource.email}' AND State__c != 'disabled'" }

          context "where there are no matching users in salesforce" do
            it "calls the select method" do
              described_class.new(sf_class, resource.id).upsert

              expect(described_class).to have_received(:select).with(query)
            end

            it "upserts, stores the salesforce id and call after upsert" do
              described_class.new(sf_class, resource.id).upsert

              expect(client).to have_received(:upsert!).with(sf_type, "resource_id_name", all_prepared_fields)
              expect(sf_resource).to have_received(:store_salesforce_id).with(salesforce_id)
              expect(sf_resource).to have_received(:after_upsert)
            end
          end

          context "where there is one matching user in salesforce" do
            let(:sf_type){ "#{described_class::SF_USER_QUERY_TYPE}" }
            let(:update_params){ all_prepared_fields.merge(Id: salesforce_id) }

            before do
              collection << sf_record
              allow(client).to receive(:update!).with(sf_type, update_params)
            end

            it "makes API call to update user on salesforce" do
              described_class.new(sf_class, resource.id).upsert

              expect(client).to have_received(:update!).with(sf_type, update_params)
            end

            it "does not raise error" do
              expect{
                described_class.new(sf_class, resource.id).upsert
              }.not_to raise_error
            end

            it "updates the salesforce identifier" do
              described_class.new(sf_class, resource.id).upsert

              expect(sf_resource).to have_received(:store_salesforce_id).with(salesforce_id)
            end
          end

          context "where there are multiple matching users in salesforce" do
            it "raises error" do
              collection << sf_record << sf_record
              dups = collection.collect{ |c| c[:Id] }
              message = "#{described_class} : #{described_class::SF_USER_QUERY_TYPE}: #{sf_resource.resource.id}, found duplicates: #{dups}"

              expect{
                described_class.new(sf_class, resource.id).upsert
              }.to raise_error(RuntimeError).with_message(message)
            end
          end
        end
      end
    end

    context "when the resource is not present" do
      let(:resource){ nil }
      let(:message){ "#{described_class} : Missing record: #{sf_class.sf_type}" }

      it "raises error" do
        expect{
          described_class.new(sf_class, nil).upsert
        }.to raise_error(RuntimeError).with_message(message)
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
