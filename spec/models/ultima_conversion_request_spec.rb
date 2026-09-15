# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UltimaConversionRequest do
  let(:ultima_preset) do
    UltimaPreset.create!(name: 'UG100 preset', application_type: 'scRNA_GEX_10x_flex', sequencing_recipe: '75 cycles')
  end
  let(:ultima_primer_a) { UltimaPrimer.create!(name: 'UGA-1') }
  let(:ultima_primer_b) { UltimaPrimer.create!(name: 'UGB-1') }
  let(:ultima_application) do
    UltimaApplication.create!(
      name: '10x Flex',
      description: '10x Genomics GEM-X Flex Gene Expression',
      ug100_preset: ultima_preset,
      ug200_preset: ultima_preset,
      uga_primer: ultima_primer_a,
      ugb_primer: ultima_primer_b
    )
  end
  let(:request) do
    build(
      :ultima_conversion_request,
      request_metadata_attributes: { ultima_application_id: ultima_application.id }
    )
  end

  describe 'metadata' do
    context 'when an ultima application is present' do
      it 'is valid' do
        expect(request).to be_valid
      end

      it 'links to the correct ultima application' do
        expect(request.ultima_application).to eq(ultima_application)
      end
    end

    context 'when the ultima application is missing' do
      before do
        request.request_metadata.ultima_application_id = nil
      end

      it 'is not valid' do
        expect(request).not_to be_valid
      end

      it 'displays the correct error' do
        request.valid?
        expect(request.errors[:'request_metadata.ultima_application']).to eq(['must exist'])
      end
    end
  end
end
