#frozen_string_literal: true

# rubocop:disable RSpec/DescribeClass
# rubocop:disable RSpec/ExampleLength
# rubocop:disable Rspec/MultipleExpectations
require 'rails_helper'
require 'rake'

RSpec.describe 'plate_creators:add_new_plate_purposes' do
  before do
    Rake.application.rake_require 'tasks/add_new_plate_purposes'
    Rake::Task.define_task(:environment)

    PlatePurpose.create!(name: 'Stock Plate')
    PlatePurpose.create!(name: 'Stock RNA Plate')
  end

  let(:task) { Rake::Task['plate_creators:add_new_plate_purposes'] }

  it 'adds new plate creators to the plate_creators table' do
    expect { task.invoke }.to change(Plate::Creator, :count).to(2)

    stock_plate_creator = Plate::Creator.find_by(name: 'Stock Plate')
    rna_plate_creator = Plate::Creator.find_by(name: 'scRNA Stock Plate')

    expect(stock_plate_creator).not_to be_nil
    expect(stock_plate_creator.valid_options).to eq({ valid_dilution_factors: [1.0] })

    expect(rna_plate_creator).not_to be_nil
    expect(rna_plate_creator.valid_options).to eq({ valid_dilution_factors: [1.0] })

    stock_plate_purpose = PlatePurpose.find_by(name: 'Stock Plate')
    rna_plate_purpose = PlatePurpose.find_by(name: 'Stock RNA Plate')

    expect(
      Plate::Creator::PurposeRelationship.find_by(
        plate_purpose_id: stock_plate_purpose.id,
        plate_creator_id: stock_plate_creator.id
      )
    ).not_to be_nil
    expect(
      Plate::Creator::PurposeRelationship.find_by(
        plate_purpose_id: rna_plate_purpose.id,
        plate_creator_id: rna_plate_creator.id
      )
    ).not_to be_nil
  end
end
# rubocop:enable RSpec/DescribeClass
# rubocop:enable RSpec/ExampleLength
# rubocop:enable Rspec/MultipleExpectations
