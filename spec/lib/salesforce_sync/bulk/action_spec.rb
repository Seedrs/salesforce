require "spec_helper"

describe SalesforceSync::Bulk::Action do
  describe ".synchronise" do
    let(:instance_delay){ double("instance_delay") }
    let(:ids){ [1, 2, 3] }

    before do
      current_time = Time.current
      Timecop.freeze(current_time)
      allow_any_instance_of(described_class).to receive(:delay).with(run_at: current_time + 30.seconds).and_return(instance_delay)
      allow(instance_delay).to receive(:synchronise)

      class KlassOne; end
      class SfKlassOne < SalesforceSync::Resource::Base; end
      class KlassTwo; end
      class SfKlassTwo < SalesforceSync::Resource::Base; end

      resources_by_class = {
        KlassOne => SfKlassOne,
        KlassTwo => KlassTwo,
      }

      allow(SalesforceSync.config).to receive(:resources_by_class).and_return(resources_by_class)
    end

    context "when there is one type of object to synchronise" do
      let(:ids_by_class){ { KlassOne => ids } }

      it "queue and start the request" do
        bulk_request = double("bulk_request")
        allow(SalesforceSync::Bulk::Request).to receive(:new).with(SfKlassOne, ids).and_return(bulk_request)

        queue_item = double("queue_item", started?: false, processing?: false, finished?: false)
        allow(SalesforceSync::Bulk::QueueItem).to receive(:new).with(bulk_request).and_return(queue_item)
        allow(queue_item).to receive(:start)

        described_class.new(:ids_by_class => ids_by_class).synchronise
        expect(queue_item).to have_received(:start).once
      end

      context "when there are more than the max number of object per request" do
        it "creates requests in batches, start the first one and check the status of the other later" do
          max_object_per_request = 2
          stub_const("SalesforceSync::Bulk::Request::MAX_OBJECT_PER_REQUEST", max_object_per_request)

          first_bulk_request = double("first_bulk_request")
          allow(SalesforceSync::Bulk::Request).to receive(:new).with(SfKlassOne, ids.first(2)).and_return(first_bulk_request)
          first_queue_item = double("first_queue_item", started?: false, processing?: false, finished?: false)
          allow(SalesforceSync::Bulk::QueueItem).to receive(:new).with(first_bulk_request).and_return(first_queue_item)
          allow(first_queue_item).to receive(:start)

          second_bulk_request = double("second_bulk_request")
          allow(SalesforceSync::Bulk::Request).to receive(:new).with(SfKlassOne, ids.last(1)).and_return(second_bulk_request)
          second_queue_item = double("second_queue_item", started?: false, processing?: false, finished?: false)
          allow(SalesforceSync::Bulk::QueueItem).to receive(:new).with(second_bulk_request).and_return(second_queue_item)
          allow(second_queue_item).to receive(:start)

          described_class.new(:ids_by_class => ids_by_class).synchronise
          expect(first_queue_item).to have_received(:start).once
          expect(second_queue_item).not_to have_received(:start)
          expect(instance_delay).to have_received(:synchronise)
        end
      end
    end

    context "when there are multiple types of objects to synchronise" do
      let(:ids_by_class){ {KlassOne => ids, KlassTwo => ids } }

      let(:first_queue_item){ double("first_queue_item", started?: false, processing?: false, finished?: false) }
      let(:second_queue_item){ double("second_queue_item", started?: false, processing?: false, finished?: false) }
      let(:queue_items){ [first_queue_item, second_queue_item] }

      before do
        first_bulk_request = double("first_bulk_request")
        allow(SalesforceSync::Bulk::Request).to receive(:new).with(SfKlassOne, ids).and_return(first_bulk_request)
        allow(SalesforceSync::Bulk::QueueItem).to receive(:new).with(first_bulk_request).and_return(first_queue_item)
        allow(first_queue_item).to receive(:start)

        second_bulk_request = double("second_bulk_request")
        allow(SalesforceSync::Bulk::Request).to receive(:new).with(KlassTwo, ids).and_return(second_bulk_request)
        allow(SalesforceSync::Bulk::QueueItem).to receive(:new).with(second_bulk_request).and_return(second_queue_item)
        allow(second_queue_item).to receive(:start)
      end

      context "when no request has started yet" do
        it "creates one request for the first one and check the other later" do
          described_class.new(ids_by_class: ids_by_class).synchronise
          expect(first_queue_item).to have_received(:start)
          expect(second_queue_item).not_to have_received(:start)
          expect(instance_delay).to have_received(:synchronise)
        end
      end

      context "when the first request is already started but not yet finished" do
        let(:first_queue_item){ double("first_queue_item", started?: true, processing?: true, finished?: false) }

        it "does not start any request and check the status later" do
          described_class.new(queue_items: queue_items).synchronise
          expect(first_queue_item).not_to have_received(:start)
          expect(second_queue_item).not_to have_received(:start)
          expect(instance_delay).to have_received(:synchronise)
        end
      end

      context "when the first request is finished" do
        let(:first_queue_item){ double("first_queue_item", started?: true, processing?: true, finished?: true) }

        it "starts the second request and check the status later" do
          described_class.new(queue_items: queue_items).synchronise
          expect(first_queue_item).to have_received(:finished?)
          expect(second_queue_item).to have_received(:start)
          expect(instance_delay).to have_received(:synchronise)
        end
      end

      context "when the two first requests are finished" do
        let(:first_queue_item){ double("first_queue_item", started?: true, processing?: true, finished?: true) }
        let(:second_queue_item){ double("second_queue_item", started?: true, processing?: true, finished?: true) }

        it "does nothing" do
          described_class.new(queue_items: queue_items).synchronise
          expect(first_queue_item).not_to have_received(:start)
          expect(second_queue_item).not_to have_received(:start)
          expect(instance_delay).not_to have_received(:synchronise)
        end
      end
    end
  end
end
