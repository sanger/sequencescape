require 'rails_helper'

RSpec.describe Accession::Accessionable, type: :model, accession: true do

  class Accessionobubble
    include Accession::Accessionable

    def ebi_alias
      "ALIAS"
    end
  end

  before(:each) do
    allow(Time).to receive(:now).and_return(Time.parse("2016-12-08T13:29:59Z"))
  end

  it "should have a file name" do
    expect(Accessionobubble.new.filename).to eq("ALIAS-2016-12-08T13:29:59Z.accessionobubble.xml")
  end


end