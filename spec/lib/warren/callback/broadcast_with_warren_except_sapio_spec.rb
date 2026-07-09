# frozen_string_literal: true

require 'rails_helper'
require 'warren/callback/broadcast_with_warren_except_sapio'

class BasicRecord
  attr_reader :id

  def initialize(id)
    @id = id
  end
end

class SapioRecord < BasicRecord
  def initialize(id, mastered_in_sapio)
    super(id)
    @mastered_in_sapio = mastered_in_sapio
  end

  def mastered_in_sapio?
    @mastered_in_sapio
  end
end

RSpec.describe Warren::Callback::BroadcastWithWarrenExceptSapio do
  let(:callback) { described_class.new(handler: Warren.handler) }

  before do
    allow(Warren.handler).to receive(:<<)
  end

  describe '#after_commit' do
    context 'when the record is mastered in Sapio' do
      let(:record) { SapioRecord.new(1, true) }

      it 'drops the message' do
        callback.after_commit(record)

        expect(Warren.handler).not_to have_received(:<<)
      end
    end

    context 'when the record is not mastered in Sapio' do
      let(:record) { SapioRecord.new(1, false) }

      it 'forwards the message' do
        callback.after_commit(record)

        expect(Warren.handler).to have_received(:<<).with(kind_of(Warren::Message::Short))
      end
    end

    context 'when the record does not define mastered_in_sapio?' do
      let(:record) { BasicRecord.new(1) }

      it 'forwards the message' do
        callback.after_commit(record)

        expect(Warren.handler).to have_received(:<<).with(kind_of(Warren::Message::Short))
      end
    end
  end
end
