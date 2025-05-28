# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssetLink, type: :model do
  # rubocop:disable RSpec/InstanceVariable,Metrics/MethodLength,RSpec/ExampleLength,RSpec/MultipleExpectations
  # Test the overridden create_edge class method.
  describe '.create_edge' do
    # Wait for child processes to finish.
    #
    # @param pids [Array<Integer>] Process IDs
    # @raise [Timeout::Error] If a child process does not finish within 10 seconds.
    # @return [void]
    def wait_for_child_processes(pids)
      exits = []
      pids
        .each
        .with_index(1) do |pid, index|
          Timeout.timeout(10) do
            _pid, status = Process.wait2(pid)
            exits << status.exitstatus
          end
        rescue Timeout::Error
          raise StandardError, "parent: Timeout waiting for child#{index} to finish"
        end

      expect(exits).to eq([0, 0])
    end

    # Delete created records.
    after do
      @ancestor&.destroy
      @descendant&.destroy
      @edge&.destroy
    end

    it 'handles race condition at find_link' do
      # In this example, the first and second processes are forked from the
      # main process and they are in race condition to find an existing link
      # between the ancestor and descendant and create an edge if no link is
      # found. Both first and second processes finds no link, but the second
      # process creates the edge first. The first also tries to create the
      # edge based on the result of the find_link method. Only one link must
      # be created.

      # Parent
      ActiveRecord::Base.connection.reconnect!
      @ancestor = ancestor = create(:labware)
      @descendant = descendant = create(:labware)
      ActiveRecord::Base.connection.commit_db_transaction

      # Create a duplex pipe for IPC.
      first_socket, second_socket = UNIXSocket.pair

      # First child
      pid1 =
        fork do
          ActiveRecord::Base.connection.reconnect!

          find_link_call_count = 0
          # Patch find_link method
          allow(described_class).to receive(:find_link).and_wrap_original do |m, *args|
            find_link_call_count += 1
            link = m.call(*args)
            if find_link_call_count == 1
              expect(link).to be_nil # No link found
              message = 'paused'
              first_socket.send(message, 0) # Notify the second child
              message = 'child1: Timeout waiting for resume message'
              raise StandardError, message unless first_socket.wait_readable(10)

              message = 'resume' # Wait for the second child to create the edge
              first_socket.recv(message.size)
            elsif find_link_call_count == 2
              expect(link).not_to be_nil # Found one now
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
          message = 'child2: Timeout waiting for paused message'
          raise StandardError, message unless second_socket.wait_readable(10)

          message = 'paused' # Wait for the first child to call find_link
          second_socket.recv(message.size)
          described_class.create_edge(ancestor, descendant)
          message = 'resume' # Notify the first child
          second_socket.send(message, 0)
          ActiveRecord::Base.connection.close
        end

      # Parent
      wait_for_child_processes([pid1, pid2])

      expect(described_class.where(ancestor:, descendant:).count).to eq(1)
      @edge = edge = described_class.last
      expect(edge.ancestor).to eq(ancestor)
      expect(edge.descendant).to eq(descendant)
      expect(edge.direct).to be_truthy
      expect(edge.count).to eq(1)

      ActiveRecord::Base.connection.close
    end

    it 'handles unique validation error' do
      # In this example, the first and second processes are forked from the
      # main process. Neither of them finds and existing link between the
      # ancestor and descendant. Both try to create the edge. One of them
      # succeeds and the other one fails due to the has_duplicates validation.
      # Failing process should use the existing link.

      # Parent
      ActiveRecord::Base.connection.reconnect!
      @ancestor = ancestor = create(:labware)
      @descendant = descendant = create(:labware)
      ActiveRecord::Base.connection.commit_db_transaction

      # Create a duplex pipe for IPC.
      first_socket, second_socket = UNIXSocket.pair

      # First child
      pid1 =
        fork do
          ActiveRecord::Base.connection.reconnect!
          find_link_call_count = 0
          allow(described_class).to receive(:find_link).and_wrap_original do |m, *args|
            find_link_call_count += 1
            link = m.call(*args)
            if find_link_call_count == 1
              expect(link).to be_nil # No link found
              message = 'paused' # Notify the second child
              first_socket.send(message, 0)
              message = 'child1: Timeout waiting for resume message'
              raise StandardError, message unless first_socket.wait_readable(10)

              message = 'resume' # Wait for the second child to create the edge
              first_socket.recv(message.size)
            end
            link
          end

          # Patch unique_validation_error? method
          unique_validation_error_return_value = nil
          allow(described_class).to receive(:unique_validation_error?).and_wrap_original do |m, *args|
            unique_validation_error_return_value = m.call(*args)
          end

          result = described_class.create_edge(ancestor, descendant)
          expect(result).to be_truthy
          expect(described_class).to have_received(:unique_validation_error?)
          expect(unique_validation_error_return_value).to be_truthy

          ActiveRecord::Base.connection.close
        end

      # Second child
      pid2 =
        fork do
          ActiveRecord::Base.connection.reconnect!
          message = 'child2: Timeout waiting for paused message'
          raise StandardError, message unless second_socket.wait_readable(10)

          message = 'paused' # Wait for the first child to call find_link
          second_socket.recv(message.size)
          described_class.create_edge(ancestor, descendant)
          message = 'resume' # Notify the first child
          second_socket.send(message, 0)
          ActiveRecord::Base.connection.close
        end

      # Parent
      wait_for_child_processes([pid1, pid2])

      expect(described_class.where(ancestor:, descendant:).count).to eq(1)
      @edge = edge = described_class.last
      expect(edge.ancestor).to eq(ancestor)
      expect(edge.descendant).to eq(descendant)
      expect(edge.direct).to be_truthy
      expect(edge.count).to eq(1)
    end

    it 'handles unique constraint violation' do
      # In this example, the first and second processes are forked from the
      # main process. Neither of them finds and existing link between the
      # ancestor and descendant. Both try to create the edge. One of them
      # succeeds and the other one fails due to the database unique constraint
      # violation. Failing process should use the existing link.

      # Parent
      ActiveRecord::Base.connection.reconnect!
      @ancestor = ancestor = create(:labware)
      @descendant = descendant = create(:labware)
      ActiveRecord::Base.connection.commit_db_transaction

      # Create a duplex pipe for IPC.
      first_socket, second_socket = UNIXSocket.pair

      # First child
      pid1 =
        fork do
          ActiveRecord::Base.connection.reconnect!
          find_link_call_count = 0
          allow(described_class).to receive(:find_link).and_wrap_original do |m, *args|
            find_link_call_count += 1
            link = m.call(*args)
            if find_link_call_count == 1
              expect(link).to be_nil
              message = 'paused' # Notify the second child
              first_socket.send(message, 0)
              message = 'child1: Timeout waiting for resume message'
              raise StandardError, message unless first_socket.wait_readable(10)

              message = 'resume' # Wait for the second child to create the edge
              first_socket.recv(message.size)
            end
            link
          end

          # Patch has_duplicates method.
          # rubocop:disable RSpec/AnyInstance
          allow_any_instance_of(Dag::CreateCorrectnessValidator).to receive(:has_duplicates).and_return(false)
          # rubocop:enable RSpec/AnyInstance

          # Patch save_edge_or_handle_error method.
          allow(described_class).to receive(:save_edge_or_handle_error).and_wrap_original do |method, *args|
            edge = args[0]
            message =
              "Duplicate entry '#{ancestor.id}-#{descendant.id}' " \
                "for key 'index_asset_links_on_ancestor_id_and_descendant_id'"
            exception = ActiveRecord::RecordNotUnique.new(message)
            allow(edge).to receive(:save).and_raise(exception)

            method.call(*args)
          end

          # Patch unique_violation_error? method.
          unique_violation_error_return_value = nil
          allow(described_class).to receive(:unique_violation_error?).and_wrap_original do |m, *args|
            unique_violation_error_return_value = m.call(*args)
          end

          result = described_class.create_edge(ancestor, descendant)
          expect(result).to be_truthy
          expect(described_class).to have_received(:unique_violation_error?)
          expect(unique_violation_error_return_value).to be_truthy

          ActiveRecord::Base.connection.close
        end

      # Second child
      pid2 =
        fork do
          ActiveRecord::Base.connection.reconnect!
          message = 'child2: Timeout waiting for paused message'
          raise StandardError, message unless second_socket.wait_readable(10)

          message = 'paused' # Wait for the first child to call find_link
          second_socket.recv(message.size)
          described_class.create_edge(ancestor, descendant)
          message = 'resume' # Notify the first child
          second_socket.send(message, 0)
          ActiveRecord::Base.connection.close
        end

      # Parent
      wait_for_child_processes([pid1, pid2])

      expect(described_class.where(ancestor:, descendant:).count).to eq(1)
      @edge = edge = described_class.last
      expect(edge.ancestor).to eq(ancestor)
      expect(edge.descendant).to eq(descendant)
      expect(edge.direct).to be_truthy
      expect(edge.count).to eq(1)

      ActiveRecord::Base.connection.close
    end
  end
  # rubocop:enable RSpec/InstanceVariable,Metrics/MethodLength,RSpec/ExampleLength,RSpec/MultipleExpectations
end
