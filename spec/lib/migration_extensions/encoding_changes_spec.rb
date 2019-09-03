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

  setup do
    ActiveRecord::Migration.verbose = false
  end

  describe '#up' do
    setup do
      expect(ActiveRecord::Base.connection).to receive(:execute)
        .with('ALTER TABLE test_table ROW_FORMAT=DYNAMIC')
      expect(ActiveRecord::Base.connection).to receive(:execute)
        .with('ALTER TABLE test_table CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci')
    end

    it 'migrates' do
      migration.migrate(:up)
    end
  end

  describe '#down' do
    setup do
      expect(ActiveRecord::Base.connection).to receive(:execute)
        .with('ALTER TABLE test_table CONVERT TO CHARACTER SET latin1 COLLATE latin1_swedish_ci')
      expect(ActiveRecord::Base.connection).to receive(:execute)
        .with('ALTER TABLE test_table ROW_FORMAT=COMPACT')
    end

    it 'migrates' do
      migration.migrate(:down)
    end
  end

  teardown do
    ActiveRecord::Migration.verbose = true
  end
end
