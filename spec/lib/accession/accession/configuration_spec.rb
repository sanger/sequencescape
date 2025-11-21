# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accession::Accessionable, :accession, type: :model do
  let(:configuration) { Accession::Configuration.new }

  it 'is comparable' do
    expect(Accession::Configuration.new).to eq(configuration)
  end

  it 'is able to add a new file' do
    configuration.add_file 'a_new_file'
    expect(Accession::Configuration::FILES.length + 1).to eq(configuration.files.length)
    expect(configuration.files).to include(:a_new_file)
    expect(configuration).to respond_to('a_new_file=')
  end

  context 'without a folder' do
    it 'is not loaded' do
      configuration.load!
      expect(configuration).not_to be_loaded
    end
  end

  context 'with a valid folder' do
    let(:folder) { File.join('spec', 'data', 'accession') }

    before do
      configuration.folder = folder
      configuration.load!
    end

    it 'is loaded' do
      expect(configuration).to be_loaded
    end

    it 'loads the tag list' do
      expect(configuration.tags).to eq(Accession::TagList.new(configuration.load_file(folder, 'tags')))
    end

    it 'freezes all of the configuration options' do
      expect(configuration.tags).to be_frozen
    end
  end
end
