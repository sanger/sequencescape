# frozen_string_literal: true

require 'rails_helper'

describe Submission::SubmissionCreator do
  describe '#order_fields' do
    let(:user) { create :user }
    let(:creator) { described_class.new(user, template_id: template.id) }

    context 'a full template' do
      let(:template) { create :libray_and_sequencing_template }

      it 'finds the appropriate order fields' do
        expect(creator.order_fields.length).to eq 5
        expect(creator.order_fields).to include(
          FieldInfo.new(display_name: 'Fragment size required (from)', key: :fragment_size_required_from, kind: 'Numeric')
        )
        expect(creator.order_fields).to include(
          FieldInfo.new(display_name: 'Fragment size required (to)', key: :fragment_size_required_to, kind: 'Numeric')
        )
        expect(creator.order_fields).to include(
          FieldInfo.new(default_value: 'Standard', display_name: 'Library type', key: :library_type, kind: 'Selection', selection: ['Standard'])
        )
        expect(creator.order_fields).to include(
          FieldInfo.new(display_name: 'PCR Cycles', key: :pcr_cycles, kind: 'Numeric')
        )
        expect(creator.order_fields).to include(
          FieldInfo.new(default_value: 54, display_name: 'Read length', key: :read_length, kind: 'Selection', selection: [37, 54, 76, 108])
        )
      end
    end
  end
end
