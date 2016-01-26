require "spec_helper"
require "turbot/client/ssl_endpoint"

describe Turbot::Client, "ssl endpoints" do
  before do
    @client = Turbot::Client.new(nil, nil)
  end

  it "adds an ssl endpoint" do
    stub_request(:post, "http://turbot.opencorporates.com/bots/example/ssl-endpoints").
      with(:body => { :accept => "json", :pem => "pem content", :key => "key content" }).
      to_return(:body => %{ {"cname": "tokyo-1050" } })
    expect(@client.ssl_endpoint_add("example", "pem content", "key content")).to eq({ "cname" => "tokyo-1050" })
  end

  it "gets info on an ssl endpoint" do
    stub_request(:get, "http://turbot.opencorporates.com/bots/example/ssl-endpoints/tokyo-1050").
      to_return(:body => %{ {"cname": "tokyo-1050" } })
    expect(@client.ssl_endpoint_info("example", "tokyo-1050")).to eq({ "cname" => "tokyo-1050" })
  end

  it "lists ssl endpoints for an bot" do
    stub_request(:get, "http://turbot.opencorporates.com/bots/example/ssl-endpoints").
      to_return(:body => %{ [{"cname": "tokyo-1050" }, {"cname": "tokyo-1051" }] })
    expect(@client.ssl_endpoint_list("example")).to eq([
      { "cname" => "tokyo-1050" },
      { "cname" => "tokyo-1051" },
    ])
  end

  it "removes an ssl endpoint" do
    stub_request(:delete, "http://turbot.opencorporates.com/bots/example/ssl-endpoints/tokyo-1050")
    @client.ssl_endpoint_remove("example", "tokyo-1050")
  end

  it "rolls back an ssl endpoint" do
    stub_request(:post, "http://turbot.opencorporates.com/bots/example/ssl-endpoints/tokyo-1050/rollback").
      to_return(:body => %{ {"cname": "tokyo-1050" } })
    expect(@client.ssl_endpoint_rollback("example", "tokyo-1050")).to eq({ "cname" => "tokyo-1050" })
  end

  it "updates an ssl endpoint" do
    stub_request(:put, "http://turbot.opencorporates.com/bots/example/ssl-endpoints/tokyo-1050").
      with(:body => { :accept => "json", :pem => "pem content", :key => "key content" }).
      to_return(:body => %{ {"cname": "tokyo-1050" } })
    expect(@client.ssl_endpoint_update("example", "tokyo-1050", "pem content", "key content")).to eq({ "cname" => "tokyo-1050" })
  end
end
