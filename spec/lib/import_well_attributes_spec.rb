# frozen_string_literal: true

require 'rails_helper'
require './lib/import_well_attributes'
# AttributeUnit.new(:gel_pass, 'gel_pass', 'status', 'Gel', 0),
# AttributeUnit.new(:concentration, 'concentration', 'ng/ul', DEFAULT_ASSAY_TYPE, 0),
# AttributeUnit.new(:current_volume, 'volume', 'ul', DEFAULT_ASSAY_TYPE, 0),
# AttributeUnit.new(:sequenom_count, 'loci_passed', 'bases', :detect_snp_assay, 0),
# AttributeUnit.new(:gender_markers, 'gender_markers', 'bases', :detect_gender_assay, 0),
# AttributeUnit.new(:measured_volume, 'volume', 'ul', 'Volume Check', -1),
# AttributeUnit.new(:initial_volume, 'volume', 'ul', 'Volume Check', -2),
# AttributeUnit.new(:molarity, 'molarity', 'nM', DEFAULT_ASSAY_TYPE, 0),
# AttributeUnit.new(:rin, 'RIN', 'RIN', DEFAULT_ASSAY_TYPE, 0)
RSpec.describe ImportWellAttributes do
  let(:updated_at) { Time.zone.parse('2018-08-20 13:08:34 +0100') }
  # This well will not have qc results generated
  let!(:ignored_well) { create :well, well_attribute_attributes: { concentration: nil, current_volume: nil, updated_at: updated_at } }
  # This well is kept nice and simple, to test the basics
  let!(:simple_well) { create :well, well_attribute_attributes: { concentration: 200, current_volume: 30, updated_at: updated_at } }
  # This well already has qc results, and shouldn't generate more
  let!(:qced_well) do
    well = create :well, well_attribute_attributes: { concentration: 200, current_volume: 30 }
    create :qc_result, asset: well, key: 'concentration', value: '200.0', units: 'ng/ul', suppress_updates: true
    # In theory we shouldn't actually see qc results which don't match their well attributes, but
    # if we do, we ignore them, as the updated_at timestamp on well_attributes might be associated
    # with a different assay. We will log the issue though.
    create :qc_result, asset: well, key: 'volume', value: 12, units: 'ng/ul', suppress_updates: true
    well
  end
  let!(:snped_well) do
    well = create :well, well_attribute_attributes: { concentration: nil, current_volume: nil, sequenom_count: 12, gender_markers: %w[M M F M Unknown] }
    well.events.update_gender_markers!('SNP')
    well.events.update_sequenom_count!('SNP')
    well
  end
  let!(:fluidigmed_well) do
    well = create :well, well_attribute_attributes: { concentration: nil, current_volume: nil, sequenom_count: 12, gender_markers: %w[M M F M Unknown] }
    # This well has been through both, but fluidigm is most recent
    well.events.update_gender_markers!('SNP')
    well.events.update_sequenom_count!('SNP')
    well.events.update_gender_markers!('FLUIDIGM')
    well.events.update_sequenom_count!('FLUIDIGM')
    well
  end
  # Single volume wells have all tree volumes the same, and only record stuff once
  let!(:single_volume_well) do
    create :well, well_attribute_attributes: { concentration: nil, current_volume: 30, measured_volume: 30, initial_volume: 30, updated_at: updated_at }
  end
  # Single volume wells have all tree volumes the same, and only record stuff once
  let!(:multi_volume_well) do
    w = create :well, well_attribute_attributes: { concentration: nil, measured_volume: 30, updated_at: updated_at }
    w.well_attribute.update(measured_volume: 20)
    w.well_attribute.update(current_volume: 10)
    w
  end

  it 'generates qc results' do
    ImportWellAttributes.import
    expect(ignored_well.qc_results.length).to eq(0)
    expect(simple_well.qc_results.length).to eq(2)
    simple_results = simple_well.qc_results.pluck(:key, :value)
    expect(simple_results).to include(['concentration', '200.0'])
    expect(simple_results).to include(['volume', '30.0'])
    expect(qced_well.qc_results.length).to eq(2)
    expect(snped_well.qc_results.length).to eq(2)
    snped_results = snped_well.qc_results.pluck(:key, :value, :assay_type)
    expect(snped_results).to include(['gender_markers', 'MMFMU', 'SNP'])
    expect(snped_results).to include(['loci_passed', '12', 'SNP'])
    expect(fluidigmed_well.qc_results.length).to eq(2)
    fluidigm_results = fluidigmed_well.qc_results.pluck(:key, :value, :assay_type)
    expect(fluidigm_results).to include(['gender_markers', 'MMFMU', 'FLUIDIGM'])
    expect(fluidigm_results).to include(['loci_passed', '12', 'FLUIDIGM'])
    expect(single_volume_well.qc_results.length).to eq(1)
    expect(multi_volume_well.qc_results.length).to eq(3)
    expect(multi_volume_well.last_qc_result_for('volume').last.value).to eq('10.0')
  end
end
