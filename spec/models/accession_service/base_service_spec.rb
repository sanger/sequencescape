# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessionService::BaseService do
  let(:service) { described_class.new }
  let(:user) { create(:user) }

  # The use of doubles here is not ideal - please don't duplicate this in other tests
  # This is planned to be removed soon in Y25-709.
  let(:accessionable) do
    double('Accessionable', errors: [], xml: '<XML/>', schema_type: 'sample', file_name: 'sample.xml') # rubocop:disable RSpec/VerifiedDoubles
  end

  before do
    allow(Accessionable::Submission).to receive(:new).and_return(double(all_accessionables: [accessionable]))
    allow(service).to receive(:post_files).and_return(xml_response)
  end

  context 'when XML response indicates failure' do
    context 'when XML response contains 1 error' do
      let(:xml_response) do
        <<-XML
        <RESPONSE success="false">
          <ERROR>Error 1</ERROR>
        </RESPONSE>
        XML
      end

      it 'raises AccessionServiceError with the error message' do
        expect do
          service.submit(user, accessionable)
        end.to raise_error(AccessionService::AccessionServiceError,
                           'Could not get accession number.  Base service returned 1 errors: Error 1')
      end
    end

    context 'when XML response contains 3 errors' do
      let(:xml_response) do
        <<-XML
        <RESPONSE success="false">
          <ERROR>Error 1</ERROR>
          <ERROR>Error 2</ERROR>
          <ERROR>Error 3</ERROR>
        </RESPONSE>
        XML
      end

      it 'raises AccessionServiceError with all errors' do
        expect do
          service.submit(user, accessionable)
        end.to raise_error(AccessionService::AccessionServiceError,
                           'Could not get accession number.  Base service returned 3 errors: Error 1; Error 2; Error 3')
      end
    end

    context 'when XML response contains more than 3 errors' do
      let(:xml_response) do
        <<-XML
        <RESPONSE success="false">
          <ERROR>Error 1</ERROR>
          <ERROR>Error 2</ERROR>
          <ERROR>Error 3</ERROR>
          <ERROR>Error 4</ERROR>
        </RESPONSE>
        XML
      end

      it 'raises AccessionServiceError with the error message' do
        expect { service.submit(user, accessionable) }
          .to raise_error(AccessionService::AccessionServiceError,
                          'Could not get accession number.  ' \
                          'Base service returned 4 errors: ' \
                          'Error 1; Error 2; Error 3 - and 1 more errors')
      end
    end
  end
end
