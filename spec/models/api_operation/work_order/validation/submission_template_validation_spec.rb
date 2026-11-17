# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::WorkOrder::Validation::SubmissionTemplateValidation do
  subject(:validation) { described_class.new(template, options) }

  let(:template) { create(:limber_wgs_submission_template) }
  let(:options) { { 'read_length' => 150, 'library_type' => library_type } }
  let(:library_type) { nil }

  before do
    request_type = template.request_types.last
    create(:sequencing_request_type_validator, request_type: request_type, options: [54, 150, 250])
  end

  it 'finds no errors when the options satisfy the request type validators' do
    expect(validation.errors).to be_empty
  end

  context 'with a value the request type validator does not allow' do
    let(:options) { { 'read_length' => 12_345 } }

    it 'points at the option' do
      expect(validation.errors.map(&:pointer)).to include('/work_order/options/read_length')
    end
  end

  context 'with a library type Sequencescape does not have' do
    let(:library_type) { 'Nonexistent' }

    it 'points at the library type' do
      expect(validation.errors.map(&:pointer)).to eq(['/work_order/options/library_type'])
    end
  end

  it 'has no scRNA warnings for other templates' do
    expect(validation.scrna_core_cdna_prep_feasibility_warnings).to be_empty
  end
end
