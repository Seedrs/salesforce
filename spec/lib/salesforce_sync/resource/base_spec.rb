require "spec_helper"

describe SalesforceSync::Resource::Base do
  describe "class methods" do
    describe "#sf_type" do
      it "raises a SalesforceSync::Error" do
        sf_error = double("sf_error")
        allow(SalesforceSync::Error).to receive(:new).and_return(sf_error)
        allow(sf_error).to receive(:raise_error)

        described_class.sf_type
        expect(sf_error).to have_received(:raise_error)
      end
    end

    describe "#resource_id_name" do
      it "raises a SalesforceSync::Error" do
        sf_error = double("sf_error")
        allow(SalesforceSync::Error).to receive(:new).and_return(sf_error)
        allow(sf_error).to receive(:raise_error)

        described_class.resource_id_name
        expect(sf_error).to have_received(:raise_error)
      end
    end
  end

  describe "instance methods" do
    let(:resource_id){ 1234 }
    let(:identifiers){ double("identifiers", count: 1, first: identifier) }
    let(:identifier){ double("identifier") }
    let(:sf_type){ double("sf_type") }

    before do
      allow(SalesforceSync::Resource::Identifier).to receive(:where).and_return(identifiers)
      allow(described_class).to receive(:sf_type).and_return(sf_type)
    end

    describe ".all_fields" do
      it "raises a SalesforceSync::Error" do
        sf_error = double("sf_error")
        allow(SalesforceSync::Error).to receive(:new).and_return(sf_error)
        allow(sf_error).to receive(:raise_error)

        described_class.new(resource_id).all_fields
        expect(sf_error).to have_received(:raise_error)
      end
    end

    describe ".field_limits" do
      it "returns an empty hash by default" do
        expect(described_class.new(resource_id).field_limits).to eq({})
      end
    end

    describe ".all_prepared_fields" do
      context "when there are fields and limits" do
        it "return the field truncated with there limit" do
          all_fields = {
            f1: "this is the first field limited with 10 char",
            f2: 12356789,
            f3: "no limit specified here"
          }

          field_limits = {
            f1: 10,
            f2: 2
          }

          epxected_all_prepared_fields = {
            f1: "this is...",
            f2: "12",
            f3: "no limit specified here"
          }

          instance = described_class.new(resource_id)
          allow(instance).to receive(:all_fields).and_return(all_fields)
          allow(instance).to receive(:field_limits).and_return(field_limits)

          expect(instance.all_prepared_fields).to eq(epxected_all_prepared_fields)
        end
      end
    end

    describe ".require_upsert?" do
      it "returns true by default" do
        expect(described_class.new(resource_id).require_upsert?).to be_truthy
      end
    end

    describe ".dependent_resources" do
      it "returns an empty array" do
        expect(described_class.new(resource_id).dependent_resources).to eq([])
      end
    end

    describe ".synchronised?" do
      context "when the salesforce_id is stored" do
        let(:identifier){ double("identifier", salesforce_id: "sf_id") }

        it "is true" do
          expect(described_class.new(resource_id).synchronised?).to be_truthy
        end
      end

      context "when the salesforce_id is not stored" do
        let(:identifier){ double("identifier", salesforce_id: nil) }

        it "is false" do
          expect(described_class.new(resource_id).synchronised?).to be_falsey
        end
      end
    end

    describe ".salesforce_id" do
      context "when the resource is synchronised" do
        let(:identifier){ double("identifier", salesforce_id: "sf_id") }

        it "returns the salesforce id" do
          expect(described_class.new(resource_id).salesforce_id).to eq("sf_id")
        end
      end

      context "when the resource is not synchronised" do
        let(:identifier){ double("identifier", salesforce_id: nil) }

        it "returns nil" do
          expect(described_class.new(resource_id).salesforce_id).to be_nil
        end
      end
    end

    describe ".url" do
      before do
        config = double("config")
        allow(SalesforceSync).to receive(:config).and_return(config)
        allow(config).to receive(:salesforce_url).and_return(sf_url)
      end

      context "when salesforce url is configured" do
        let(:sf_url){ "sf_url" }

        context "when the resource is synchronised" do
          let(:identifier){ double("identifier", salesforce_id: "sf_id") }

          it "returns the resource url" do
            expect(described_class.new(resource_id).url).to eq("sf_url/sf_id")
          end
        end

        context "when the resource is not synchronised" do
          let(:identifier){ double("identifier", salesforce_id: nil) }

          it "returns nil" do
            expect(described_class.new(resource_id).url).to be_nil
          end
        end
      end

      context "when salesforce url is not configured" do
        let(:sf_url){ "" }

        it "raises a SalesforceSync::Error" do
          sf_error = double("sf_error")
          allow(SalesforceSync::Error).to receive(:new).and_return(sf_error)
          allow(sf_error).to receive(:raise_error)

          described_class.new(resource_id).url
          expect(sf_error).to have_received(:raise_error)
        end
      end
    end

    describe ".store_salesforce_id" do
      before do
        allow(identifier).to receive(:salesforce_id=).with(salesforce_id)
        allow(identifier).to receive(:save!)
      end

      context "when salesforce_id is provided" do
        let(:salesforce_id){ "sf_id" }

        it "stores the identifier with the id" do
          described_class.new(resource_id).store_salesforce_id(salesforce_id)
          expect(identifier).to have_received(:salesforce_id=).with(salesforce_id)
          expect(identifier).to have_received(:save!)
        end
      end

      context "when salesforce_id is not provided" do
        let(:salesforce_id){ nil }

        it "does not store the identifier with the id" do
          described_class.new(resource_id).store_salesforce_id(salesforce_id)
          expect(identifier).not_to have_received(:salesforce_id=).with(salesforce_id)
          expect(identifier).not_to have_received(:save!)
        end
      end
    end
  end
end
