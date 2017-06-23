require "spec_helper"

describe SalesforceSync::Resource::Factory do
  describe "#create" do
    it "returns a instance of the sf_class" do
      resource = double("resource", class: "klass", id: 1234)
      sf_class = double("sf_class")
      sf_class_instance = double("sf_class_instance")
      allow(described_class).to receive(:sf_class).with(resource.class).and_return(sf_class)
      allow(sf_class).to receive(:new).with(resource.id).and_return(sf_class_instance)

      expect(described_class.create(resource)).to eq(sf_class_instance)
    end
  end

  describe "#sf_class" do
    before do
      class Klass; end
      class SfClass < SalesforceSync::Resource::Base; end

      resources_by_class = { Klass => SfClass }
      config = double("config", resources_by_class: resources_by_class)
      allow(SalesforceSync).to receive(:config).and_return(config)
    end

    context "when the Klass is provided" do
      it "returns the configured SfClass" do
        expect(described_class.sf_class(Klass)).to eq(SfClass)
      end
    end

    context "when the ChildKlass is provided" do
      it "returns the configured SfClass of the parent class" do
        class ChildKlass < Klass; end
        expect(described_class.sf_class(ChildKlass)).to eq(SfClass)
      end
    end

    context "when an unknown class is provided" do
      it "raises an error" do
        class UnknownKlass; end
        sf_error = double("sf_error")
        allow(SalesforceSync::Error).to receive(:new).and_return(sf_error)
        allow(sf_error).to receive(:raise_error)

        described_class.sf_class(UnknownKlass)
        expect(sf_error).to have_received(:raise_error)
      end
    end
  end

  describe "#resource_class" do
    before do
      class Klass; end
      class SfClass < SalesforceSync::Resource::Base; end

      resources_by_class = { Klass => SfClass }
      config = double("config", resources_by_class: resources_by_class)
      allow(SalesforceSync).to receive(:config).and_return(config)
    end

    context "when the SfClass is provided" do
      it "returns the configured Klass" do
        expect(described_class.resource_class(SfClass)).to eq(Klass)
      end
    end

    context "when an unknown class is provided" do
      it "raises an error" do
        class UnknownKlass; end
        sf_error = double("sf_error")
        allow(SalesforceSync::Error).to receive(:new).and_return(sf_error)
        allow(sf_error).to receive(:raise_error)

        described_class.resource_class(UnknownKlass)
        expect(sf_error).to have_received(:raise_error)
      end
    end
  end
end
