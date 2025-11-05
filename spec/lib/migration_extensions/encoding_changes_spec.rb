# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MigrationExtensions::EncodingChanges do
  let(:migration) do
    Class.new(ActiveRecord::Migration[5.1]) do
      include MigrationExtensions::EncodingChanges

      def change
        change_encoding 'test_table', from: 'latin1', to: 'utf8mb4'
      end
    end
  end

  before { ActiveRecord::Migration.verbose = false }

  describe '#up' do
    it 'migrates' do
      expect(ActiveRecord::Base.with_connection).to receive(:execute).with('ALTER TABLE test_table ROW_FORMAT=DYNAMIC')
      expect(ActiveRecord::Base.with_connection).to receive(:execute).with(
        'ALTER TABLE test_table CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci'
      )
      migration.migrate(:up)
    end
  end

  describe '#down' do
    it 'migrates' do
      expect(ActiveRecord::Base.with_connection).to receive(:execute).with(
        'ALTER TABLE test_table CONVERT TO CHARACTER SET latin1 COLLATE latin1_swedish_ci'
      )
      expect(ActiveRecord::Base.with_connection).to receive(:execute).with('ALTER TABLE test_table ROW_FORMAT=COMPACT')
      migration.migrate(:down)
    end
  end

  teardown { ActiveRecord::Migration.verbose = true }
end
