# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accession::Accessionable, :accession, type: :model do
  context 'with a class that includes Accessionable' do
    class Accessionobubble
      include Accession::Accessionable

      def ebi_alias
        'ALIAS'
      end

      def build_xml(xml)
        xml.ACCESSIONOBUBBLE 'Pop!'
      end
    end

    before { allow(Time).to receive(:now).and_return(Time.zone.parse('2016-12-08T13:29:59Z')) }

    it 'has a date stamped alias' do
      expect(Accessionobubble.new.ebi_alias_datestamped).to eq('ALIAS-2016-12-08T13:29:59Z')
    end

    it 'has a file name' do
      expect(Accessionobubble.new.filename).to eq('ALIAS-2016-12-08T132959Z.accessionobubble.xml')
    end

    it 'has some xml' do
      expect(Accessionobubble.new.to_xml).to be_present
    end

    it 'has create a file with some text' do
      accessionable = Accessionobubble.new
      file = accessionable.to_file
      file.open
      text = file.read
      expect(text).to include(accessionable.to_xml)
      expect(text.last).to eq("\n")
      file.close!
    end

    it 'creates a file with the correct filename' do
      accessionable = Accessionobubble.new
      file = accessionable.to_file
      expect(file.path).to end_with("_#{accessionable.filename}")
      file.close!
    end
  end

  context 'when loading configuration' do
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
end
