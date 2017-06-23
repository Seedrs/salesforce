require "spec_helper"

describe SalesforceSync::Bulk::QueueItem do
  describe ".start" do
    it "creates a job to process the requests" do
      request = double("request", sf_class: "sf_class")
      delay_request = double("delay_request")
      expected_delay_params = { queue: "Sf_sync_bulk_sf_class" }
      allow(request).to receive(:delay).with(expected_delay_params).and_return(delay_request)
      allow(delay_request).to receive(:process)

      described_class.new(request).start
      expect(request).to have_received(:delay).with(expected_delay_params)
      expect(delay_request).to have_received(:process)
    end
  end

  describe ".started" do
    context "when it is started" do
      it "is true" do
        delay_request = double("delay_request", process: nil)
        instance = described_class.new(double("request", sf_class: "sf_class", delay: delay_request))
        instance.start
        expect(instance.started?).to be_truthy
      end
    end

    context "when it is not started" do
      it "is true" do
        instance = described_class.new(double("request"))
        expect(instance.started?).to be_falsey
      end
    end
  end

  describe ".finished?" do
    let(:job_count){ 0 }
    let(:instance){ described_class.new(double("request", sf_class: "sf_class", delay: double("delay_request", process: nil))) }
    before do
      allow(Delayed::Job).to receive(:where).with(queue: "Sf_sync_bulk_sf_class").and_return(double("delay_requests", count: job_count))
    end

    context "when it is started" do
      before{ instance.start }

      context "when a process request job is present" do
        let(:job_count){ 1 }

        it "is not finished" do
          expect(instance.finished?).to be_falsey
        end
      end

      context "when no process request job is present" do
        let(:job_count){ 0 }

        it "is finished" do
          expect(instance.finished?).to be_truthy
        end
      end
    end

    context "when it is not started" do
      it "is false" do
        expect(instance.finished?).to be_falsey
      end
    end
  end
end
