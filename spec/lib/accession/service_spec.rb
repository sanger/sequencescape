require 'rails_helper'

RSpec.describe Accession::Service, type: :model, accession: true do

  it "can have a provider" do
    service = Accession::Service.new("open")
    expect(service.provider).to eq(:ENA)
    expect(service).to be_ena

    service = Accession::Service.new("managed")
    expect(service.provider).to eq(:EGA)
    expect(service).to be_ega
  end

  it "should not be valid without a provider" do
    service = Accession::Service.new("closed")
    expect(service.provider).to be_nil
    expect(service).to_not be_valid
  end

  it "should have a uri if the service is valid" do
    service = Accession::Service.new("open")
    expect(service.url).to be_present

    service = Accession::Service.new("managed")
    expect(service.url).to be_present

    service = Accession::Service.new("closed")
    expect(service.url).to be_nil
  end

  it "should have visibility" do
    service = Accession::Service.new("open")
    expect(service.visibility).to eq("HOLD")

    service = Accession::Service.new("managed")
    expect(service.visibility).to eq("PROTECT")
  end

end