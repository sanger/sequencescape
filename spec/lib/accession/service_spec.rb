# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accession::Service, type: :model, accession: true do
  it 'can have a provider' do
    service = Accession::Service.new('open')
    expect(service.provider).to eq(:ENA)
    expect(service).to be_ena

    service = Accession::Service.new('managed')
    expect(service.provider).to eq(:EGA)
    expect(service).to be_ega
  end

  it 'is not valid without a provider' do
    service = Accession::Service.new('closed')
    expect(service.provider).to be_nil
    expect(service).not_to be_valid
  end

  it 'has a uri if the service is valid' do
    service = Accession::Service.new('open')
    expect(service.url).to be_present

    service = Accession::Service.new('managed')
    expect(service.url).to be_present

    service = Accession::Service.new('closed')
    expect(service.url).to be_nil
  end

  it 'has visibility' do
    service = Accession::Service.new('open')
    expect(service.visibility).to eq('HOLD')

    service = Accession::Service.new('managed')
    expect(service.visibility).to eq('PROTECT')
  end

  it 'can have a broker' do
    service = Accession::Service.new('open')
    expect(service.broker).not_to be_present

    service = Accession::Service.new('managed')
    expect(service.broker).to eq('EGA')
  end

  it 'can have a user and password' do
    service = Accession::Service.new('open')
    expect(service.login).to eq(configatron.accession.ena!.to_hash)

    service = Accession::Service.new('managed')
    expect(service.login).to eq(configatron.accession.ega!.to_hash)

    service = Accession::Service.new('closed')
    expect(service.login).to be_nil
  end
end
