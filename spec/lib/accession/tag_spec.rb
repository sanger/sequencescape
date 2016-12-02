require 'rails_helper'

RSpec.describe Accession::Tag, type: :model do

  it "should only be valid with a name and a parent" do
    expect(Accession::Tag.new(name: :tag_1, parent: "name")).to be_valid
    expect(Accession::Tag.new(name: :tag_1)).to_not be_valid
    expect(Accession::Tag.new(parent: "name")).to_not be_valid
  end

  it "should indicate which services it is required for" do
    tag = Accession::Tag.new(services: :ENA)
    expect(tag.required_for?(:ENA)).to be_truthy
    expect(tag.required_for?(:EGA)).to be_falsey

    tag = Accession::Tag.new(services: [:ENA, :EGA])
    expect(tag.required_for?(:ENA)).to be_truthy
    expect(tag.required_for?(:EGA)).to be_truthy

    tag = Accession::Tag.new
    expect(tag.required_for?(:ENA)).to be_falsey
    expect(tag.required_for?(:EGA)).to be_falsey
  end

  it "should indicate whether it is an array express field" do
    expect(Accession::Tag.new(array_express: true)).to be_array_express
    expect(Accession::Tag.new).to_not be_array_express
  end

  it "should be able to add a value" do
    expect(Accession::Tag.new(value: "Value 1").value).to eq("Value 1")
    expect(Accession::Tag.new.add_value("Value 2").value).to eq("Value 2")
  end
    
end