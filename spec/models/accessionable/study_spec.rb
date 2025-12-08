# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Accessionable::Study, type: :model do
  let(:user) { create(:user) }
  let(:study_metadata) { create(:study_metadata, study_ebi_accession_number: nil) }
  let(:study) { create(:study, study_metadata:) }
  let(:accessionable_study) { described_class.new(study) }
  let(:accession_number) { 'ENA123' }

  describe '#update_accession_number!' do
    before do
      accessionable_study.update_accession_number!(user, accession_number)
    end

    it 'updates the accession number' do
      expect(study.study_metadata.study_ebi_accession_number).to eq(accession_number)
    end

    it 'creates an event' do
      event = study.events.order(:created_at).last
      expect(event).to have_attributes(
        message: 'Created study accession number',
        content: nil,
        of_interest_to: 'administrators',
        created_by: user.login
      )
    end
  end
end
