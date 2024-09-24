# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssetLink, type: :model do
  describe '.create_edge' do

    after do
      @ancestor.destroy if @ancestor
      @descendant.destroy if @descendant
    end

    # rubocop:disable RSpec/ExampleLength
    it 'handles race condition at find_link' do
      # Parent
      ActiveRecord::Base.connection.reconnect!
      @ancestor = ancestor = create(:labware)
      @descendant = descendant = create(:labware)
      ActiveRecord::Base.connection.commit_db_transaction

      first_socket, second_socket = UNIXSocket.pair

      # First child
      pid1 =
        fork do
          ActiveRecord::Base.connection.reconnect!
          ancestor = Labware.find(ancestor.id)
          descendant = Labware.find(descendant.id)
          find_link_call_count = 0
          allow(described_class).to receive(:find_link).and_wrap_original do |m, *args|
            find_link_call_count += 1
            link = m.call(*args)
            if find_link_call_count == 1
              expect(link).to be_nil
              message = 'paused'
              first_socket.send(message, 0)
              message = 'child1: Timeout waiting for resume message'
              raise StandardError, message unless first_socket.wait_readable(10)
              message = 'resume'
              first_socket.recv(message.size)
            elsif find_link_call_count == 2
              expect(link).not_to be_nil
            end
            link
          end
          described_class.create_edge(ancestor, descendant)
          ActiveRecord::Base.connection.close
        end

      # Second child
      pid2 =
        fork do
          ActiveRecord::Base.connection.reconnect!
          ancestor = Labware.find(ancestor.id)
          descendant = Labware.find(descendant.id)
          message = 'child2: Timeout waiting for paused message'
          raise StandardError, message unless second_socket.wait_readable(10)
          message = 'paused'
          second_socket.recv(message.size)
          described_class.create_edge(ancestor, descendant)
          message = 'resume'
          second_socket.send(message, 0)
          ActiveRecord::Base.connection.close
        end

      # Parent
      [pid1, pid2].each
        .with_index(1) do |pid, index|
          Timeout.timeout(10) { Process.waitpid(pid) }
        rescue Timeout::Error
          raise StandardError, "parent: Timeout waiting for child#{index} to finish"
        end

      expect(described_class.where(ancestor: ancestor, descendant: descendant).count).to eq(1)
      link = described_class.last
      expect(link.ancestor).to eq(ancestor)
      expect(link.descendant).to eq(descendant)
      expect(link.direct).to be_truthy
      expect(link.count).to eq(1)

      ActiveRecord::Base.connection.close
    end
    # rubocop:enable RSpec/ExampleLength
  end
end
