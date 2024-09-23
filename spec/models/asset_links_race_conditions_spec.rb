# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssetLink, type: :model do
  describe '.create_edge' do
    # Helpers

    # Used in IPC when one end of the duplex pipe is waiting for the other end
    # to send a message with a timeout in seconds.
    #
    # @param socket [Socket] The socket to wait for.
    # @param length [Integer] The length of the message to wait for.
    # @param timeout [Integer] The timeout in seconds, default is 10.
    # @param message [String] The message to raise if times out, default is 'socket timeout'.
    # @return [String] The message received from the socket.
    # @raise StandardError
    def wait_readable_with_timeout(socket, length, timeout = 10, message = 'socket timeout')
      raise StandardError, message unless socket.wait_readable(timeout)
      socket.recv(length)
    end

    # Used to reap a child process with a timeout in seconds.
    #
    # @param pid [Integer] The process ID to wait for.
    # @param timeout [Integer] The timeout in seconds, default is 10.
    # @param message [String] The message to raise if times out, default is 'process timeout'.
    # @return [Process::Status] The status of the process.
    # @raise StandardError
    # rubocop:disable Metrics/MethodLength
    def wait_process_with_timeout(pid, timeout = 10, message = 'process timeout')
      start_time = Time.zone.now
      loop do
        begin
          pid2, status = Process.waitpid2(pid, Process::WNOHANG)
          return status if pid2
        rescue Errno::ECHILD # No child process
          return nil
        end
        if Time.zone.now - start_time > timeout
          begin
            Process.kill('TERM', pid) # Send TERM signal.
            sleep 1 # Wait for the process to terminate.
            Process.kill('KILL', pid) # Send KILL signal.
            Process.waitpid(pid) # Reap
          rescue Errno::ECHILD
            # No child process
          end
          raise StandardError, message
        end
        sleep 0.1
      end
    end
    # rubocop:enable Metrics/MethodLength

    # Wait for the given processes to finish with a timeout in seconds.
    # @param pids [Array<Integer>] The process IDs to wait for.
    # @return [void]
    def wait_for_processes(pids)
      pids.each do |pid|
        status = wait_process_with_timeout(pid, 10, "Timeout waiting for process #{pid} to finish.")
        if status.exitstatus != 0
          raise StandardError, "Forked process #{pid} failed with exit status #{status.exitstatus}"
        end
      end
    end

    # Examples

    # rubocop:disable RSpec/ExampleLength
    it 'handles race condition at find_link' do
      # In this example, the first and second processes are forked from the
      # main process and they are in race condition to find an existing link
      # between the ancestor and descendant and create an edge if no link is
      # found. Both first and second processes finds no link, but the second
      # process creates the edge first. The first also tries to create the
      # edge based on the result of the find_link method. However, it must
      # not be able to create it.

      ActiveRecord::Base.connection.reconnect!
      ancestor = create(:labware)
      descendant = create(:labware)
      ActiveRecord::Base.connection.commit_db_transaction

      # Create a duplex pipe for inter-process communication.
      first_socket, second_socket = Socket.pair(:UNIX, :STREAM)

      # Fork the first process.
      pid1 =
        fork do
          ActiveRecord::Base.connection.reconnect!

          call_count = 0 # Track the calls to the find_link method.

          # Patch the find_link method in the first process.
          allow(described_class).to receive(:find_link).and_wrap_original do |method, *args|
            call_count += 1
            link = method.call(*args)
            if call_count == 1
              expect(link).to be_nil # The first process should not find any link initally.

              signal = 'paused'
              first_socket.send(signal, 0) # Signal that the first process is paused now. Zero flags.

              # Wait for the second process to send 'resume'.
              wait_readable_with_timeout(
                first_socket,
                'resume'.length,
                10,
                'Timeout waiting for the second process to send resume.'
              )
            elsif call_count == 2
              # The first process now should find the link created by the second process.
              expect(link).not_to be_nil
            end
            link
          end

          described_class.create_edge(ancestor, descendant)
          ActiveRecord::Base.connection.close
        end

      # Fork the second process.
      pid2 =
        fork do
          ActiveRecord::Base.connection.reconnect! # Reconnect to the database in the forked process.

          # Wait for the first process to signal that it is paused after calling find_link.
          wait_readable_with_timeout(
            second_socket,
            'paused'.length,
            10,
            'Timeout waiting for the first process to send paused.'
          )

          described_class.create_edge(ancestor, descendant)
          # Signal the first process to resume now. Although it has found no link
          # in its last method call, actually there is one now.
          signal = 'resume'
          second_socket.send(signal, 0) # Zero flags.
          ActiveRecord::Base.connection.close
        end

      # Wait for both processes to finish and check their exit statuses
      wait_for_processes([pid1, pid2])

      # Check that the edge was created as expected.
      expect(described_class.where(ancestor: ancestor, descendant: descendant).count).to eq(1)
      link = described_class.last
      expect(link.ancestor).to eq(ancestor)
      expect(link.descendant).to eq(descendant)
      expect(link.direct).to be_truthy
      expect(link.count).to eq(1)

      ActiveRecord::Base.connection.close
    end
    # rubocop:enable RSpec/ExampleLength

    # rubocop:disable RSpec/ExampleLength
    it 'handles race condition at has_duplicates' do
      # In this example, the first and second processes are forked from the
      # main process. Neither of them finds and existing link between the
      # ancestor and descendant. Both try to create the edge. One of them
      # succeeds and the other one fails due to the has_duplicates validation.
      # Failing process should use the existing link.

      ActiveRecord::Base.connection.reconnect!
      ancestor = create(:labware)
      descendant = create(:labware)
      ActiveRecord::Base.connection.commit_db_transaction

      # Create a duplex pipe for inter-process communication.
      first_socket, second_socket = Socket.pair(:UNIX, :STREAM)

      # Fork the first process.
      pid1 =
        fork do
          ActiveRecord::Base.connection.reconnect!
          call_count = 0 # Track the calls to the find_link method.
          # Patch the find_link method in the first process.
          # Check link, trigger the second process, pause, and then wait for'resume' signal.
          allow(described_class).to receive(:find_link).and_wrap_original do |method, *args|
            call_count += 1
            link = method.call(*args)
            if call_count == 1
              expect(link).to be_nil # The first process should not find any link initally.
              signal = 'paused'
              first_socket.send(signal, 0) # Signal that the first process is paused now. Zero flags.
              # Wait for the second process to send 'resume'.
              wait_readable_with_timeout(
                first_socket,
                'resume'.length,
                10,
                'Timeout waiting for the second process to send resume.'
              )
            end
            link
          end
          allow(described_class).to receive(:unique_validation_error?).and_call_original

          # Now the first process should be prevented from saving because of has_duplicates validation.
          result = described_class.create_edge(ancestor, descendant)
          expect(result).to be_truthy
          expect(described_class).to have_received(:unique_validation_error?)

          ActiveRecord::Base.connection.close
        end

      # Fork the second process.
      pid2 =
        fork do
          ActiveRecord::Base.connection.reconnect!
          # Wait for the first process to signal that it is paused after calling find_link.
          wait_readable_with_timeout(
            second_socket,
            'paused'.length,
            10,
            'Timeout waiting for the first process to send paused.'
          )
          described_class.create_edge(ancestor, descendant)
          signal = 'resume'
          second_socket.send(signal, 0) # Zero flags.
          ActiveRecord::Base.connection.close
        end

      # Wait for both processes to finish and check their exit statuses
      wait_for_processes([pid1, pid2])

      # Check that the edge was created as expected.
      expect(described_class.where(ancestor: ancestor, descendant: descendant).count).to eq(1)
      link = described_class.last
      expect(link.ancestor).to eq(ancestor)
      expect(link.descendant).to eq(descendant)
      expect(link.direct).to be_truthy
      expect(link.count).to eq(1) # How many different paths between the nodes.
    end
    # rubocop:enable RSpec/ExampleLength

    # rubocop:disable RSpec/ExampleLength
    it 'handles unique constraint violation' do
      # In this example, the first and second processes are forked from the
      # main process. Neither of them finds and existing link between the
      # ancestor and descendant. Both try to create the edge. One of them
      # succeeds and the other one fails due to the unique constraint
      # violation. Failing process should use the existing link.

      ActiveRecord::Base.connection.reconnect!
      ancestor = create(:labware)
      descendant = create(:labware)
      ActiveRecord::Base.connection.commit_db_transaction

      # Create a duplex pipe for inter-process communication.
      first_socket, second_socket = Socket.pair(:UNIX, :STREAM)

      # Fork the first process.
      pid1 =
        fork do
          ActiveRecord::Base.connection.reconnect!
          call_count = 0 # Track the calls to the find_link method.
          # Patch the find_link method in the first process.
          # Check link, trigger the second process, pause, and then wait for'resume' signal.
          allow(described_class).to receive(:find_link).and_wrap_original do |method, *args|
            call_count += 1
            link = method.call(*args)
            if call_count == 1
              expect(link).to be_nil # The first process should not find any link initally.
              signal = 'paused'
              first_socket.send(signal, 0) # Signal that the first process is paused now. Zero flags.
              # Wait for the second process to send 'resume'.
              wait_readable_with_timeout(
                first_socket,
                'resume'.length,
                10,
                'Timeout waiting for the second process to send resume.'
              )
            end
            link
          end
          # Validation error is not triggered in this case because the other
          # process has not saved the link yet. Therefore, the save call will
          # pass the validations and hit the database to trigger the unique
          # constraint violation just after the other process saves the link.
          # rubocop:disable RSpec/AnyInstance
          allow_any_instance_of(Dag::CreateCorrectnessValidator).to receive(:has_duplicates).and_return(false)
          # rubocop:enable RSpec/AnyInstance

          allow(described_class).to receive(:save_edge_or_handle_error).and_wrap_original do |method, *args|
            edge = args[0]
            message =
              "Duplicate entry '#{ancestor.id}-#{descendant.id}' " \
                "for key 'index_asset_links_on_ancestor_id_and_descendant_id'"
            exception = ActiveRecord::RecordNotUnique.new(message)
            allow(edge).to receive(:save).and_raise(exception)

            method.call(*args)
          end
          allow(described_class).to receive(:unique_violation_error?).and_call_original

          described_class.create_edge(ancestor, descendant)
          expect(described_class).to have_received(:unique_violation_error?)
          ActiveRecord::Base.connection.close
        end

      # Fork the second process.
      pid2 =
        fork do
          ActiveRecord::Base.connection.reconnect! # Reconnect to the database in the forked process.

          # Wait for the first process to signal that it is paused after calling find_link.
          wait_readable_with_timeout(
            second_socket,
            'paused'.length,
            10,
            'Timeout waiting for the first process to send paused.'
          )

          described_class.create_edge(ancestor, descendant)
          # Signal the first process to resume now. Although it has found no link
          # in its last method call, actually there is one now.
          signal = 'resume'
          second_socket.send(signal, 0) # Zero flags.
          ActiveRecord::Base.connection.close
        end

      # Wait for both processes to finish and check their exit statuses
      wait_for_processes([pid1, pid2])

      # Check that the edge was created as expected.
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
