require "spec_helper"

describe SalesforceSync::Resource::Event do
  describe ".push" do
    let(:salesforce_id){ "sf_id" }
    let(:resource){ double("resource") }
    let(:changed_attributes){ { "first_name" => "yop", "last_name" => "yap" } }
    let(:queue_item){ double("queue_item") }
    let(:sf_resource){ double("sf_resource") }
    let(:instance){ described_class.new(event_name, resource, changed_attributes) }

    before do
      allow(SalesforceSync::Resource::Factory).to receive(:create).with(resource).and_return(sf_resource)
      allow(SalesforceSync::Resource::QueueItem).to receive(:new).with(resource).and_return(queue_item)
    end

    context "when the event is a destroy event" do
      let(:event_name){ "resource.destroy" }

      it "pulls upsert job and push a destroy in the queue" do
        allow(queue_item).to receive(:pull_upsert)
        allow(queue_item).to receive(:push_destroy)

        instance.push
        expect(queue_item).to have_received(:pull_upsert)
        expect(queue_item).to have_received(:push_destroy)
      end
    end

    context "when the event is an upsert event" do
      let(:event_name){ "resource.create" }

      before do
        allow(queue_item).to receive(:push_upsert)
        allow(sf_resource).to receive(:require_upsert?).and_return(resource_require_upsert?)
        allow(sf_resource).to receive(:dependent_resources).and_return(dependent_resources)
        dependent_resources.each_with_index do |dependent_resource, index|
          allow(SalesforceSync::Api).to receive(:synchronised?).with(dependent_resource).and_return(dependent_synchronised?)
          allow(SalesforceSync::Resource::QueueItem).to receive(:new).with(dependent_resource).and_return(dependent_resource_queue_items[index])
          allow(dependent_resource_queue_items[index]).to receive(:push_upsert).with(true)
        end
      end

      context "when the resource require to be upserted" do
        let(:resource_require_upsert?){ true }

        context "when the resource has dependent resources" do
          let(:dependent_resources){ [double("dependent_1"), double("dependent_2")] }
          let(:dependent_resource_queue_items){ [double("dependent_queue_item_1"), double("dependent_queue_item_2")] }

          context "when the dependent resources are not yet synchronised" do
            let(:dependent_synchronised?){ false }

            it "pushes upsert for the dependent and the resource" do
              instance.push
              expect(queue_item).to have_received(:push_upsert)
              dependent_resource_queue_items.each do |dependent_resource_queue_item|
                expect(dependent_resource_queue_item).to have_received(:push_upsert).with(true)
              end
            end
          end

          context "when the dependent resources are synchronised" do
            let(:dependent_synchronised?){ true }

            it "pushes upsert only the resource" do
              instance.push
              expect(queue_item).to have_received(:push_upsert)
              dependent_resource_queue_items.each do |dependent_resource_queue_item|
                expect(dependent_resource_queue_item).not_to have_received(:push_upsert).with(true)
              end
            end
          end
        end

        context "when the resource has no dependent resource" do
          let(:dependent_resources){ [] }
          let(:dependent_resource_queue_items){ [] }

          it "push upsert for the resource" do
            instance.push
            expect(queue_item).to have_received(:push_upsert)
          end
        end

        context "when one dependent resource is nil" do
          let(:dependent_resources){ [double("dependent_1"), nil] }
          let(:dependent_resource_queue_items){ [double("dependent_queue_item_1"), double("dependent_queue_item_2")] }

          context "when the dependent resources are not yet synchronised" do
            let(:dependent_synchronised?){ false }

            it "pushes upsert for the present dependent and the resource" do
              instance.push
              expect(queue_item).to have_received(:push_upsert)
              expect(dependent_resource_queue_items[0]).to have_received(:push_upsert).with(true)
              expect(SalesforceSync::Api).not_to receive(:synchronised?).with(nil)
              expect(dependent_resource_queue_items[1]).not_to have_received(:push_upsert)
            end
          end
        end
      end

      context "when the resource does not require to be upserted" do
        let(:resource_require_upsert?){ false }
        let(:dependent_resources){ [double("dependent_1"), double("dependent_2")] }
        let(:dependent_resource_queue_items){ [double("dependent_queue_item_1"), double("dependent_queue_item_2")] }
        let(:dependent_synchronised?){ false }

        it "does not upsert neither the resource nor its dependents" do
          instance.push
          expect(queue_item).not_to have_received(:push_upsert)
          dependent_resource_queue_items.each do |dependent_resource_queue_item|
            expect(dependent_resource_queue_item).not_to have_received(:push_upsert).with(true)
          end
        end
      end
    end

    context "when the event is unknown" do
      let(:event_name){ "resource.event" }

      it "raises an error" do
        sf_error = double("sf_error")
        allow(SalesforceSync::Error).to receive(:new).and_return(sf_error)
        allow(sf_error).to receive(:raise_error)

        instance.push
        expect(sf_error).to have_received(:raise_error)
      end
    end
  end
end
