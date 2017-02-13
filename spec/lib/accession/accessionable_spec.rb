require 'rails_helper'

RSpec.describe Accession::Accessionable, type: :model, accession: true do
  class Accessionobubble
    include Accession::Accessionable

    def ebi_alias
      'ALIAS'
    end
  end

  before(:each) do
    allow(Time).to receive(:now).and_return(Time.parse('2016-12-08T13:29:59Z'))
  end

  it 'has a date stamped alias' do
    expect(Accessionobubble.new.ebi_alias_datestamped).to eq('ALIAS-2016-12-08T13:29:59Z')
  end

  it 'should have a file name' do
    expect(Accessionobubble.new.filename).to eq('ALIAS-2016-12-08T13:29:59Z.accessionobubble.xml')
  end

  it 'should have some xml' do
    expect(Accessionobubble.new.to_xml).to be_present
  end

  it 'should have create a file with some text and the correct filename' do
    accessionable = Accessionobubble.new
    file = accessionable.to_file
    file.open
    text = file.read
    expect(text).to include(accessionable.to_xml)
    expect(text.last).to eq("\n")
    expect(file.original_filename).to eq(accessionable.filename)
    file.close!
  end
end
