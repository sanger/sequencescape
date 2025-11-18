# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accession::Service, :accession, type: :model do
  it 'can have a provider' do
    service = described_class.new('open')
    expect(service.provider).to eq(:ENA)
    expect(service).to be_ena

    service = described_class.new('managed')
    expect(service.provider).to eq(:EGA)
    expect(service).to be_ega
  end

  it 'is not valid without a provider' do
    service = described_class.new('closed')
    expect(service.provider).to be_nil
    expect(service).not_to be_valid
  end

  it 'has a uri if the service is valid' do
    service = described_class.new('open')
    expect(service.url).to be_present

    service = described_class.new('managed')
    expect(service.url).to be_present

    service = described_class.new('closed')
    expect(service.url).to be_nil
  end

  it 'has visibility' do
    service = described_class.new('open')
    expect(service.visibility).to eq('HOLD')

    service = described_class.new('managed')
    expect(service.visibility).to eq('PROTECT')
  end

  it 'can have a broker' do
    service = described_class.new('open')
    expect(service.broker).not_to be_present

    service = described_class.new('managed')
    expect(service.broker).to eq('EGA')
  end

  it 'can have a user and password' do
    service = described_class.new('open')
    expect(service.login).to eq(configatron.accession.ena!.to_hash)

    service = described_class.new('managed')
    expect(service.login).to eq(configatron.accession.ega!.to_hash)

    service = described_class.new('closed')
    expect(service.login).to be_nil
  end
end
