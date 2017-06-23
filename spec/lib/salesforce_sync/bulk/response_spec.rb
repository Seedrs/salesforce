require "spec_helper"

describe SalesforceSync::Bulk::Response do
  describe "#successful?" do
    context "when all results are successful" do
      it "is true" do
        response = {
          "batches" => [
            { "response" => [{ "success" => ["true"] }] },
            { "response" => [{ "success" => ["true"] }] },
            { "response" => [{ "success" => ["true"] }] }
          ]
        }

        expect(described_class.new(response).successful?).to be_truthy
      end
    end

    context "when all results are not successful" do
      it "is false" do
        response = {
          "batches" => [
            { "response" => [{ "success" => ["true"] }] },
            { "response" => [{ "success" => ["true"] }] },
            { "response" => [{ "success" => ["false"] }] }
          ]
        }

        expect(described_class.new(response).successful?).to be_falsey
      end
    end
  end

  describe "#error_message" do
    it "returns the error message" do
      salesforce_url = "sf_url"
      allow(SalesforceSync.config).to receive(:salesforce_url).and_return(salesforce_url)
      response = { "id" => ["job_id"] }

      expected_error_message = "Salesforce bulk api request error, investigate #{salesforce_url}/#{response["id"][0]}"
      expect(described_class.new(response).error_message).to eq(expected_error_message)
    end
  end

  describe "#salesforce_ids" do
    it "returns the salesforce_ids" do
      response = {
        "batches" => [
          { "response" => [{ "id" => ["id_1"] }] },
          { "response" => [{ "id" => ["id_2"] }] },
          { "response" => [{ "id" => ["id_3"] }] }
        ]
      }

      expect(described_class.new(response).salesforce_ids).to eq(%w(id_1 id_2 id_3))
    end
  end
end
