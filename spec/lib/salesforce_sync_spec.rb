require "spec_helper"

describe SalesforceSync do
  describe "#start" do
    context "when salesforce_sync is active" do
      it "subscribe the resource to the list of events" do
        events = %w(user.create user.destroy)
        config = double("config", active: true, events: events)
        allow(SalesforceSync).to receive(:config).and_return(config)
        allow(EventBus).to receive(:subscribe).with("user.create")
        allow(EventBus).to receive(:subscribe).with("user.destroy")

        described_class.start
        expect(EventBus).to have_received(:subscribe).with("user.create")
        expect(EventBus).to have_received(:subscribe).with("user.destroy")
      end
    end

    context "when salesforce_sync is not active" do
      it "does not subscribe the resource to the list of events" do
        events = %w(user.create user.destroy)
        config = double("config", active: false, events: events)
        allow(SalesforceSync).to receive(:config).and_return(config)
        allow(EventBus).to receive(:subscribe).with("user.create")
        allow(EventBus).to receive(:subscribe).with("user.destroy")

        described_class.start
        expect(EventBus).not_to have_received(:subscribe).with("user.create")
        expect(EventBus).not_to have_received(:subscribe).with("user.destroy")
      end
    end
  end
end
