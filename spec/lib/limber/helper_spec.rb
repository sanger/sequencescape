# frozen_string_literal: true
require 'rails_helper'

describe Limber::Helper do
  subject(:template_constructor) do
    described_class::TemplateConstructor.new(
      prefix: 'WGS',
      catalogue: catalogue,
      sequencing_keys: [request_type.key],
      type: request_type.key
    )
  end

  let(:catalogue) { create(:product_catalogue) }
  let(:request_type) { create(:request_type) }

  before do
    # Required for various helper methods to build correctly
    create(:request_type, key: 'limber_multiplexing')
    create(:request_type, key: 'cherrypick_for_limber')
  end

  describe '#attributes' do
    it 'returns the correct attributes' do
      expect(template_constructor.name).to eq 'WGS'
      expect(template_constructor.type).to eq request_type.key
      expect(template_constructor.role).to eq 'WGS'
      expect(template_constructor.pipeline).to eq Limber::Helper::PIPELINE
      expect(template_constructor.product_line).to eq Limber::Helper::PRODUCTLINE
      expect(template_constructor.catalogue).to eq catalogue
      expect(template_constructor.prefix).to eq 'WGS'
    end
  end

  describe 'build!' do
    it 'returns false if validation fails' do
      expect(template_constructor).to be_valid
      template_constructor.catalogue = nil
      expect { template_constructor.build! }.to raise_error(ActiveModel::ValidationError)
      expect(template_constructor.errors[:catalogue]).to include('can\'t be blank')
    end

    it 'builds the submission templates based on the constructor information' do
      expect { template_constructor.build! }.to change(SubmissionTemplate, :count).by(1)
      expect(SubmissionTemplate.last.submission_class_name).to eq 'LinearSubmission'
      expect(SubmissionTemplate.last.product_catalogue).to eq catalogue
      expect(SubmissionTemplate.last.superceded_by_id).to eq(-1)
    end

    it 'sets the superceded_by_id to -2 for Hiseq templates' do
      hiseq_request_type = create(:request_type, key: 'hiseq', name: 'Hiseq')
      # Add a hiseq request type to the sequencing keys
      hiseq_template_constructor =
        described_class::TemplateConstructor.new(
          prefix: 'WGS',
          catalogue: catalogue,
          sequencing_keys: [hiseq_request_type.key],
          type: request_type.key
        )
      expect { hiseq_template_constructor.build! }.to change(SubmissionTemplate, :count).by(1)
      expect(SubmissionTemplate.last.superceded_by_id).to eq(-2)
    end
  end
end
