require "spec_helper"

describe SalesforceSync::Resource::QueueItem do
  describe ".push_upsert" do
    let(:resource){ double("resource", class: "Klass", id: 12345) }
    let(:instance){ described_class.new(resource) }
    let(:action){ double("action") }
    let(:sf_class) do
      class SfClass; end
      SfClass
    end
    let(:config){ double("config", job_identifier_column: :queue, queue_waiting_time: 1.minute) }
    let(:now){ Time.current }

    before do
      Timecop.freeze(now)
      allow(SalesforceSync::Resource::Factory).to receive(:sf_class).with("Klass").and_return(sf_class)
      allow(SalesforceSync::Resource::Action).to receive(:new).and_return(action)
      allow(SalesforceSync).to receive(:config).and_return(config)
    end

    context "when run later" do
      let(:run_now){ false }

      context "when upsert late is not in the queue" do
        before do
          queued_job_count = 0
          allow(Delayed::Job).to receive(:where).with(queue: "Sf_Upsert_SfClass_12345").and_return(double("queued_jobs", count: queued_job_count))
        end

        it "creates a delayed upsert action to run later" do
          delayed_action = double("delayed_action")
          allow(delayed_action).to receive(:upsert)

          delay_params = {
            queue: "Sf_Upsert_SfClass_12345",
            run_at: now + 1.minute
          }

          allow(action).to receive(:delay).with(delay_params).and_return(delayed_action)

          instance.push_upsert(run_now)
          expect(action).to have_received(:delay).with(delay_params)
          expect(delayed_action).to have_received(:upsert)
        end
      end

      context "when upsert late is in the queue" do
        before do
          queued_job_count = 1
          allow(Delayed::Job).to receive(:where).with(queue: "Sf_Upsert_SfClass_12345").and_return(double("queued_jobs", count: queued_job_count))
        end

        it "does not create a delayed upsert action to run later" do
          delayed_action = double("delayed_action")
          allow(delayed_action).to receive(:upsert)

          delay_params = {
            queue: "Sf_Upsert_SfClass_12345",
            run_at: now + 1.minute
          }

          allow(action).to receive(:delay).with(delay_params).and_return(delayed_action)

          instance.push_upsert(run_now)
          expect(action).not_to have_received(:delay).with(delay_params)
          expect(delayed_action).not_to have_received(:upsert)
        end
      end
    end

    context "when run now" do
      let(:run_now){ true }

      context "when upsert later is in queue" do
        before do
          queued_job_count = 1
          allow(Delayed::Job).to receive(:where).with(queue: "Sf_Upsert_SfClass_12345").and_return(double("queued_jobs", count: queued_job_count))
        end

        context "when upsert now is not in the queue" do
          before do
            queued_job_count = 0
            allow(Delayed::Job).to receive(:where).with(queue: "Sf_Upsert_SfClass_12345_now").and_return(double("queued_jobs", count: queued_job_count))
          end

          it "removes the delayed action to upsert later and creates another delayed action to upsert now" do
            jobs = double("jobs")
            job_condition = "queue = ? OR queue = ?"
            allow(Delayed::Job).to receive(:where).with(job_condition, "Sf_Upsert_SfClass_12345_now", "Sf_Upsert_SfClass_12345").and_return(jobs)
            allow(jobs).to receive(:destroy_all)

            delayed_action = double("delayed_action")
            allow(delayed_action).to receive(:upsert)

            delay_params = { queue: "Sf_Upsert_SfClass_12345_now" }

            allow(action).to receive(:delay).with(delay_params).and_return(delayed_action)

            instance.push_upsert(run_now)
            expect(Delayed::Job).to have_received(:where).with(job_condition, "Sf_Upsert_SfClass_12345_now", "Sf_Upsert_SfClass_12345")
            expect(jobs).to have_received(:destroy_all)

            expect(action).to have_received(:delay).with(delay_params)
            expect(delayed_action).to have_received(:upsert)
          end
        end
      end

      context "when upsert later is not in queue" do
        before do
          queued_job_count = 0
          allow(Delayed::Job).to receive(:where).with(queue: "Sf_Upsert_SfClass_12345").and_return(double("queued_jobs", count: queued_job_count))
        end

        context "when upsert now is not in the queue" do
          before do
            queued_job_count = 0
            allow(Delayed::Job).to receive(:where).with(queue: "Sf_Upsert_SfClass_12345_now").and_return(double("queued_jobs", count: queued_job_count))
          end

          it "does not remove the delayed action to upsert later but creates another delayed action to upsert now" do
            jobs = double("jobs")
            job_condition = "queue = ? OR queue = ?"
            allow(Delayed::Job).to receive(:where).with(job_condition, "Sf_Upsert_SfClass_12345_now", "Sf_Upsert_SfClass_12345").and_return(jobs)
            allow(jobs).to receive(:destroy_all)

            delayed_action = double("delayed_action")
            allow(delayed_action).to receive(:upsert)

            delay_params = { queue: "Sf_Upsert_SfClass_12345_now" }

            allow(action).to receive(:delay).with(delay_params).and_return(delayed_action)

            instance.push_upsert(run_now)
            expect(Delayed::Job).not_to have_received(:where).with(job_condition, "Sf_Upsert_SfClass_12345_now", "Sf_Upsert_SfClass_12345")
            expect(jobs).not_to have_received(:destroy_all)

            expect(action).to have_received(:delay).with(delay_params)
            expect(delayed_action).to have_received(:upsert)
          end
        end

        context "when upsert now is in the queue" do
          before do
            queued_job_count = 1
            allow(Delayed::Job).to receive(:where).with(queue: "Sf_Upsert_SfClass_12345_now").and_return(double("queued_jobs", count: queued_job_count))
          end

          it "does not remove the delayed action to upsert later and does not create another delayed action to upsert now" do
            jobs = double("jobs")
            job_condition = "queue = ? OR queue = ?"
            allow(Delayed::Job).to receive(:where).with(job_condition, "Sf_Upsert_SfClass_12345_now", "Sf_Upsert_SfClass_12345").and_return(jobs)
            allow(jobs).to receive(:destroy_all)

            delayed_action = double("delayed_action")
            allow(delayed_action).to receive(:upsert)

            delay_params = { queue: "Sf_Upsert_SfClass_12345_now" }

            allow(action).to receive(:delay).with(delay_params).and_return(delayed_action)

            instance.push_upsert(run_now)
            expect(Delayed::Job).not_to have_received(:where).with(job_condition, "Sf_Upsert_SfClass_12345_now", "Sf_Upsert_SfClass_12345")
            expect(jobs).not_to have_received(:destroy_all)

            expect(action).not_to have_received(:delay).with(delay_params)
            expect(delayed_action).not_to have_received(:upsert)
          end
        end
      end
    end
  end

  describe ".pull_upsert" do
    let(:resource){ double("resource", class: "Klass", id: 12345) }
    let(:instance){ described_class.new(resource) }
    let(:action){ double("action") }
    let(:sf_class) do
      class SfClass; end
      SfClass
    end
    let(:config){ double("config", job_identifier_column: :queue, queue_waiting_time: 1.minute) }

    before do
      allow(SalesforceSync::Resource::Factory).to receive(:sf_class).with("Klass").and_return(sf_class)
      allow(SalesforceSync::Resource::Action).to receive(:new).and_return(action)
      allow(SalesforceSync).to receive(:config).and_return(config)
    end

    it "destorys all possibly created upsert action" do
      jobs = double("jobs")
      job_condition = "queue = ? OR queue = ?"
      allow(Delayed::Job).to receive(:where).with(job_condition, "Sf_Upsert_SfClass_12345_now", "Sf_Upsert_SfClass_12345").and_return(jobs)
      allow(jobs).to receive(:destroy_all)

      instance.pull_upsert
      expect(Delayed::Job).to have_received(:where).with(job_condition, "Sf_Upsert_SfClass_12345_now", "Sf_Upsert_SfClass_12345")
      expect(jobs).to have_received(:destroy_all)
    end
  end

  describe ".push_destroy" do
    let(:resource){ double("resource", class: "Klass", id: 12345) }
    let(:instance){ described_class.new(resource) }
    let(:action){ double("action") }
    let(:sf_class) do
      class SfClass; end
      SfClass
    end
    let(:config){ double("config", job_identifier_column: :queue, queue_waiting_time: 1.minute) }

    before do
      allow(SalesforceSync::Resource::Factory).to receive(:sf_class).with("Klass").and_return(sf_class)
      allow(SalesforceSync::Resource::Action).to receive(:new).and_return(action)
      allow(SalesforceSync).to receive(:config).and_return(config)
    end

    it "creates a delayed action to destroy the resource" do
      delayed_action = double("delayed_action")
      allow(action).to receive(:delay).and_return(delayed_action)
      allow(delayed_action).to receive(:destroy)

      instance.push_destroy
      expect(action).to have_received(:delay)
      expect(delayed_action).to have_received(:destroy)
    end
  end
end
