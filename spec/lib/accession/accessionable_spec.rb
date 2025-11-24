# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accession::Accessionable, :accession, type: :model do
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
