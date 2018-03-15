# frozen_string_literal: true

require 'rails_helper'
require 'pry'

RSpec.describe SampleManifest::Uploader, type: :model, sample_manifest_excel: true do
  before(:all) do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.tag_group = 'My Magic Tag Group'
      config.load!
    end
  end

  let(:test_file) { 'test_file.xlsx' }
  let(:user) { create :user }

  it 'will not be valid without a filename' do
    expect(SampleManifest::Uploader.new(nil, SampleManifestExcel.configuration, user)).to_not be_valid
  end

  it 'will not be valid without some configuration' do
    download = build(:test_download, columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup)
    download.save(test_file)
    expect(SampleManifest::Uploader.new(test_file, nil, user)).to_not be_valid
  end

  it 'will not be valid without a tag group' do
    SampleManifestExcel.configuration.tag_group = nil
    download = build(:test_download, columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup)
    download.save(test_file)
    expect(SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, user)).to_not be_valid
    SampleManifestExcel.configuration.tag_group = 'My Magic Tag Group'
  end

  it 'will not be valid without a user' do
    download = build(:test_download, columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup)
    download.save(test_file)
    expect(SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, nil)).to_not be_valid
  end

  it 'will upload a valid sample manifest' do
    broadcast_events_count = BroadcastEvent.count
    download = build(:test_download, columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup)
    download.save(test_file)
    Delayed::Worker.delay_jobs = false
    uploader = SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, user)
    uploader.run!
    expect(uploader).to be_processed
    expect(BroadcastEvent.count).to eq broadcast_events_count + 1
    expect(uploader.upload.sample_manifest).to be_completed
    Delayed::Worker.delay_jobs = true
    File.delete(test_file) if File.exist?(test_file)
  end

  it 'will not upload an invalid sample manifest' do
    download = build(:test_download, columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup, manifest_type: 'multiplexed_library', validation_errors: [:tags])
    download.save(test_file)
    uploader = SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, user)
    expect(uploader).to_not be_valid
    expect(uploader.errors).to_not be_empty
    expect(uploader.upload).to_not be_processed
    File.delete(test_file) if File.exist?(test_file)
  end

  it 'will upload a valid partial tube sample manifest' do
    download = build(:test_partial_download, columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup)
    download.save(test_file)
    Delayed::Worker.delay_jobs = false
    uploader = SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, user)
    uploader.run!
    expect(uploader).to be_processed
    Delayed::Worker.delay_jobs = true
    File.delete(test_file) if File.exist?(test_file)
  end

  it 'will upload a valid partial multiplexed library tube sample manifest' do
    download = build(:test_partial_download, manifest_type: 'multiplexed_library', columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup)
    download.save(test_file)
    Delayed::Worker.delay_jobs = false
    uploader = SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, user)
    uploader.run!
    expect(uploader).to be_processed
    Delayed::Worker.delay_jobs = true
    File.delete(test_file) if File.exist?(test_file)
  end
  after(:all) do
    SampleManifestExcel.reset!
  end
end
