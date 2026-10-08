# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifest::CompoundSampleBuilder do
  let(:study) { create(:study) }
  let(:receptacle) { create(:empty_sample_tube).receptacle }
  let(:tags) { create_list(:tag, 2) }
  let(:components) do
    [9606, 10_090].map do |taxon_id|
      create(
        :sample,
        sample_metadata_attributes: {
          supplier_name: 'POOL-1',
          sample_common_name: 'Homo sapiens',
          sample_taxon_id: taxon_id
        }
      )
    end
  end
  let(:tags_by_component) { components.zip(tags).to_h }
  let(:builder) do
    described_class.new(
      study: study,
      receptacle: receptacle,
      tags_by_component: tags_by_component,
      library_type: 'My library type'
    )
  end
  let!(:compound) { builder.build! }
  let(:aliquot) { receptacle.aliquots.first }

  it 'creates the compound sample in the study' do
    expect(study.reload.samples).to include(compound)
  end

  it 'names the compound sample with a new sanger sample id' do
    expect(compound.name).to start_with(study.abbreviation)
  end

  it 'links the component samples to the compound sample' do
    expect(compound.component_samples).to match_array(components)
  end

  it 'stores the tag of each component sample on its link' do
    links = compound.joins_as_compound_sample
    expect(links.to_h { |link| [link.component_sample, link.tag] })
      .to eq(tags_by_component)
  end

  it 'puts only the compound sample in the receptacle' do
    expect(receptacle.aliquots.map(&:sample)).to eq([compound])
  end

  it 'sets the library type of the aliquot' do
    expect(aliquot.library_type).to eq('My library type')
  end

  it 'does not tag the aliquot' do
    expect(aliquot.tag).to be_nil
  end

  it 'copies the metadata that all the component samples share' do
    expect(compound.sample_metadata).to have_attributes(
      supplier_name: 'POOL-1',
      sample_common_name: 'Homo sapiens'
    )
  end

  it 'does not copy the metadata the component samples differ in' do
    expect(compound.sample_metadata.sample_taxon_id).to be_nil
  end

  describe '#update!' do
    let(:metadata) { compound.reload.sample_metadata }
    let(:links) { compound.reload.joins_as_compound_sample }
    let(:new_tag) { create(:tag) }

    def update_with(tags_by_component)
      described_class.new(study:, receptacle:, tags_by_component:)
        .update!(compound)
    end

    it 'adds a new component sample with its tag' do
      new_component = create(:sample)
      update_with(new_component => new_tag)
      expect(links.find_by(component_sample: new_component).tag).to eq(new_tag)
    end

    it 'corrects the tag of a component sample' do
      update_with(components.first => new_tag)
      expect(links.find_by(component_sample: components.first).tag)
        .to eq(new_tag)
    end

    it 'keeps the component samples it is not given' do
      update_with({})
      expect(compound.reload.component_samples).to match_array(components)
    end

    it 'takes the corrected metadata the component samples share' do
      components.each { |c| c.sample_metadata.update!(supplier_name: 'POOL-2') }
      update_with({})
      expect(metadata.supplier_name).to eq('POOL-2')
    end

    it 'clears the metadata the component samples no longer share' do
      components.first.sample_metadata.update!(sample_common_name: 'Mouse')
      update_with({})
      expect(metadata.sample_common_name).to be_nil
    end
  end
end
