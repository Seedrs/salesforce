require "spec_helper"

describe SalesforceSync::Error do
  describe "#raise_error" do
    context "when raise_on_airbrake" do
      it "notifies airbrake and raises an error" do
        config = double("config", raise_on_airbrake: true)
        allow(SalesforceSync).to receive(:config).and_return(config)
        airbrake = class_double("Airbrake").as_stubbed_const
        allow(airbrake).to receive(:notify)

        expect{ described_class.new(double("klass"), "error").raise_error }.to raise_error(RuntimeError)
        expect(airbrake).to have_received(:notify)
      end
    end

    context "do not when raise_on_airbrake" do
      it "raises an error but do not notify Airbrake" do
        config = double("config", raise_on_airbrake: false)
        allow(SalesforceSync).to receive(:config).and_return(config)
        airbrake = class_double("Airbrake").as_stubbed_const
        allow(airbrake).to receive(:notify)

        expect{ described_class.new(double("klass"), "error").raise_error }.to raise_error(RuntimeError)
        expect(airbrake).not_to have_received(:notify)
      end
    end
  end
end
