# frozen_string_literal: true

require 'rails_helper'

class WarrenExceptExternallyManagedTestRecord < ApplicationRecord
  self.table_name = 'studies'
end

class BasicRecord
  include Warren::Callback
  include Warren::Callback::ExceptExternallyManaged

  attr_reader :id

  def initialize(id:)
    @id = id
  end
end

class ExternallyManagedRecord < BasicRecord
  def initialize(id:, externally_managed:)
    super(id:)
    @externally_managed = externally_managed
  end

  def externally_managed?
    @externally_managed
  end
end

RSpec.describe Warren::Callback::ExceptExternallyManaged do
  describe '#broadcast_except_externally_managed' do
    before do
      allow(Warren.handler).to receive(:<<)
    end

    context 'when the record is externally managed' do
      let(:record) { ExternallyManagedRecord.new(id: 1, externally_managed: true) }

      it 'does not broadcast the record' do
        record.broadcast_except_externally_managed

        expect(Warren.handler).not_to have_received(:<<)
      end
    end

    context 'when the record is not externally managed' do
      let(:record) { ExternallyManagedRecord.new(id: 1, externally_managed: false) }

      it 'broadcasts the record' do
        record.broadcast_except_externally_managed

        expect(Warren.handler).to have_received(:<<)
          .with(an_instance_of(Warren::Message::Full))
      end
    end

    context 'when the record does not define externally_managed?' do
      let(:record) { BasicRecord.new(id: 1) }

      it 'broadcasts the record' do
        record.broadcast_except_externally_managed

        expect(Warren.handler).to have_received(:<<)
          .with(an_instance_of(Warren::Message::Full))
      end
    end
  end

  describe '.broadcast_with_warren_except_externally_managed' do
    before do
      allow(WarrenExceptExternallyManagedTestRecord).to receive(:after_commit)
    end

    it 'adds the after_commit callback' do
      WarrenExceptExternallyManagedTestRecord.broadcast_with_warren_except_externally_managed

      expect(WarrenExceptExternallyManagedTestRecord).to have_received(:after_commit)
        .with(an_instance_of(Warren::Callback::BroadcastWithWarrenExceptExternallyManaged))
    end
  end
end
