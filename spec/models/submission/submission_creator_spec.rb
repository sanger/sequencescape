# frozen_string_literal: true

require 'rails_helper'

describe Submission::SubmissionCreator do
  describe '#order_fields' do
    let(:user) { create(:user) }
    let(:creator) { described_class.new(user, template_id: template.id) }

    context 'a full template' do
      let(:library_type) { create(:library_type) }
      let(:library_creation_request_type) { create(:library_request_type, :with_library_types, library_type:) }
      let(:template) do
        create(:submission_template, request_types: [library_creation_request_type, create(:sequencing_request_type)])
      end

      it 'finds the appropriate order fields' do
        expect(creator.order_fields.length).to eq 6
        expect(creator.order_fields).to include(
          FieldInfo.new(
            display_name: 'Fragment size required (from)',
            key: :fragment_size_required_from,
            kind: 'Numeric'
          )
        )
        expect(creator.order_fields).to include(
          FieldInfo.new(display_name: 'Fragment size required (to)', key: :fragment_size_required_to, kind: 'Numeric')
        )
        expect(creator.order_fields).to include(
          FieldInfo.new(
            default_value: library_type.name,
            display_name: 'Library type',
            key: :library_type,
            kind: 'Selection',
            selection: [library_type.name]
          )
        )
        expect(creator.order_fields).to include(
          FieldInfo.new(display_name: 'PCR Cycles', key: :pcr_cycles, kind: 'Numeric')
        )
        expect(creator.order_fields).to include(
          FieldInfo.new(
            default_value: 54,
            display_name: 'Read length',
            key: :read_length,
            kind: 'Selection',
            selection: [37, 54, 76, 108]
          )
        )
      end
    end

    describe '#NovaSeqX read length options' do
      let(:library_type) { create(:library_type) }
      let(:library_creation_request_type) { create(:library_request_type, :with_library_types, library_type:) }
      let(:template) do
        create(
          :submission_template,
          request_types: [library_creation_request_type, create(:nova_seq_x_sequencing_request_type)]
        )
      end

      it 'includes the correct read_length options' do
        read_length_field = creator.order_fields.find { |f| f.key == :read_length }

        expect(read_length_field).to be_present
        expect(read_length_field.kind).to eq 'Selection'
        expect(read_length_field.selection).to contain_exactly(50, 100, 150)
        expect(read_length_field.default_value).to eq 50
      end
    end
  end
end
