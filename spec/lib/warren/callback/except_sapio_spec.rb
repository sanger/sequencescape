# frozen_string_literal: true

require 'rails_helper'

class WarrenExceptSapioTestRecord < ApplicationRecord
  self.table_name = 'studies'
end

class BasicRecord
  include Warren::Callback
  include Warren::Callback::ExceptSapio

  attr_reader :id

  def initialize(id:)
    @id = id
  end
end

class SapioRecord < BasicRecord
  def initialize(id:, mastered_in_sapio:)
    super(id:)
    @mastered_in_sapio = mastered_in_sapio
  end

  def mastered_in_sapio?
    @mastered_in_sapio
  end
end

RSpec.describe Warren::Callback::ExceptSapio do
  describe '#broadcast_except_sapio' do
    before do
      allow(Warren.handler).to receive(:<<)
    end

    context 'when the record is mastered in Sapio' do
      let(:record) { SapioRecord.new(id: 1, mastered_in_sapio: true) }

      it 'does not broadcast the record' do
        record.broadcast_except_sapio

        expect(Warren.handler).not_to have_received(:<<)
      end
    end

    context 'when the record is not mastered in Sapio' do
      let(:record) { SapioRecord.new(id: 1, mastered_in_sapio: false) }

      it 'broadcasts the record' do
        record.broadcast_except_sapio

        expect(Warren.handler).to have_received(:<<)
          .with(an_instance_of(Warren::Message::Full))
      end
    end

    context 'when the record does not define mastered_in_sapio?' do
      let(:record) { BasicRecord.new(id: 1) }

      it 'broadcasts the record' do
        record.broadcast_except_sapio

        expect(Warren.handler).to have_received(:<<)
          .with(an_instance_of(Warren::Message::Full))
      end
    end
  end

  describe '.broadcast_with_warren_except_sapio' do
    before do
      allow(WarrenExceptSapioTestRecord).to receive(:after_commit)
    end

    it 'adds the after_commit callback' do
      WarrenExceptSapioTestRecord.broadcast_with_warren_except_sapio

      expect(WarrenExceptSapioTestRecord).to have_received(:after_commit)
        .with(an_instance_of(Warren::Callback::BroadcastWithWarrenExceptSapio))
    end
  end
end
