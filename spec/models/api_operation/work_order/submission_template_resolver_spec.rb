# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::WorkOrder::SubmissionTemplateResolver do
  subject(:resolver) { described_class.new(api_operation) }

  let(:work_order) do
    {
      service_name: 'Human Exome',
      sequencing_platform: 'NovaSeq6000'
    }
  end
  let(:api_operation) { create(:api_operation, payload: { work_order: }.to_json) }

  it 'extracts the service and platform from the payload' do
    expect(resolver).to have_attributes(service_name: 'Human Exome', sequencing_platform: 'NovaSeq6000')
  end

  describe 'validation' do
    it 'is valid with a service name' do
      expect(resolver).to be_valid
    end

    it 'requires a service name' do
      work_order[:service_name] = ''
      resolver.validate
      expect(resolver.errors).to include(:service_name)
    end

    it 'refuses to resolve a template when invalid' do
      work_order.delete(:service_name)
      expect { resolver.submission_template }.to raise_error(ActiveModel::ValidationError)
    end
  end

  describe '#submission_template' do
    let!(:expected) { create(:submission_template, name: 'Limber-Htp - ISC - NovaSeq 6000 Paired end sequencing') }

    before { create(:submission_template, name: 'Limber-Htp - ISC - NovaSeqX paired end sequencing') }

    it 'appends the platform to the configured template name' do
      expect(resolver.submission_template).to eq(expected)
    end

    it 'uses the configured name alone without a platform' do
      work_order.delete(:sequencing_platform)
      template = create(:submission_template, name: 'Limber-Htp - ISC')
      expect(resolver.submission_template).to eq(template)
    end

    it 'raises for an unknown service' do
      work_order[:service_name] = 'Nope'
      expect { resolver.submission_template }.to raise_error(ApiOperation::Error)
    end

    it 'raises when the template does not exist' do
      work_order[:sequencing_platform] = 'MiSeq'
      expect { resolver.submission_template }.to raise_error(StandardError, /Cannot find template/)
    end

    it 'raises when the template is deprecated' do
      work_order[:service_name] = 'Custom panel ultra low input DNA (LCMB) - FS-shear'
      work_order.delete(:sequencing_platform)
      create(:submission_template, name: 'Limber-Htp - LCMB', superceded_by_id: 1)
      expect { resolver.submission_template }.to raise_error(StandardError, /deprecated/)
    end
  end
end
