require 'rails_helper'

RSpec.describe Accession::Accessionable, type: :model, accession: true do
  let(:configuration) { Accession::Configuration.new }

  it 'should be comparable' do
    expect(Accession::Configuration.new).to eq(configuration)
  end

  it 'should be able to add a new file' do
    configuration.add_file 'a_new_file'
    expect(Accession::Configuration::FILES.length + 1).to eq(configuration.files.length)
    expect(configuration.files).to include(:a_new_file)
    expect(configuration).to respond_to('a_new_file=')
  end

  context 'without a folder' do
    it 'should not be loaded' do
      configuration.load!
      expect(configuration).to_not be_loaded
    end
  end

  context 'with a valid folder' do
    let(:folder)  { File.join('spec', 'data', 'accession') }

    before(:each) do
      configuration.folder = folder
      configuration.load!
    end

    it 'should be loaded' do
      expect(configuration).to be_loaded
    end

    it 'should load the tag list' do
      expect(configuration.tags).to eq(Accession::TagList.new(configuration.load_file(folder, 'tags')))
    end

    it 'should freeze all of the configuration options' do
      expect(configuration.tags).to be_frozen
    end
  end
end
