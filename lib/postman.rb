require 'bunny'
require_relative 'postman/state_machine'
require_relative 'postman/channel'
require_relative 'postman/message'

# A postman listens to a rabbitMQ message queues
# and manages state and reconnection.
class Postman
  extend StateMachine::Helper
  # Maximum wait time between database retries: 5 minutes
  MAX_RECONNECT_DELAY = 60 * 5

  attr_reader :client, :state, :main_exchange

  def initialize(client:, main_exchange:)
    @client = client
    @consumer_tag = "qbm_#{Rails.env}_#{Process.pid}"
    @state = :initialized
    @main_exchange = main_exchange
  end

  states :stopping, :stopped, :paused, :starting, :started, :running
  delegate :warn, :info, :error, :debug, to: :logger

  def logger
    Rails.logger
  end

  def alive?
    !stopped?
  end

  def run!
    starting!
    trap_signals
    @client.start # Start the client
    main_exchange.activate! # Set up the queues
    running!            # Transition to running state
    subscribe!          # Subscribe to the queue
    # Monitor our state to control stopping and re-connection
    # This loop blocks until the state is :stopped
    control_loop while alive?
    # And we leave the application
    info "Stopped #{@consumer_tag}"
    info 'Goodbye!'
  ensure
    @client.close
  end

  def stop!
    stopping!
    STDOUT.puts "Stopping #{@consumer_tag}"
  end

  def pause!
    return unless running?

    unsubscribe!
    @recovery_attempts = 0
    @recover_at = Time.current
    paused!
  end

  private

  # Capture the term signal and set the state to stopping.
  # We can't directly cancel the consumer from here as Bunny
  # uses Mutex locking while checking the state. Ruby forbids this
  # from inside a trap block.
  # INT is triggered by Ctrl-C and we provide a manual override to
  # kill things a little quicker as this will mostly happen in
  # development.
  def trap_signals
    Signal.trap('TERM') { stop! }
    Signal.trap('INT') { manual_stop! }
  end

  # The control loop. Checks the state of the process every three seconds
  # stopping: cancels the consumer, sets the processes to stopped and breaks the loop
  # stopped: (alive? returns false) terminates the loop.
  # anything else: waits three seconds and tries again
  def control_loop
    if stopping?
      unsubscribe!
      stopped!
    else
      attempt_recovery if paused?
      sleep(3)
    end
  end

  # Our consumer operates in another thread. It is non blocking.
  # While a blocking consumer would be convenient, it causes problems:
  # 1. @consumer never gets set, requiring up instead to instantiate it first, then use subscribe_with
  # 2. We are still unable to call @consumer.cancel in our trap, give the aforementioned restrictions
  # 3. However, as our main thread is locked, we don't have anywhere else to handle the shutdown from
  # 4. There doesn't seem to be much gained from spinning up the control loop in its own thread
  def subscribe!
    raise StandardError, 'Consumer already exists' unless @consumer.nil?

    @consumer ||= @main_exchange.subscribe(@consumer_tag) do |delivery_info, metadata, payload|
      process(delivery_info, metadata, payload)
    end
  end

  # Cancels the consumer and unregisters it
  def unsubscribe!
    @consumer.try(:cancel)
    @consumer = nil
  end

  # Rest for database recovery and restore the consumer.
  def attempt_recovery
    return unless recovery_due?

    warn "Attempting recovery of database connection: #{@recovery_attempts}"
    if recovered?
      running!
      subscribe!
    else
      @recovery_attempts += 1
      @recover_at = Time.current + delay_for_attempt
    end
  end

  def delay_for_attempt
    [2**@recovery_attempts, MAX_RECONNECT_DELAY].min
  end

  def recovery_due?
    Time.current > @recover_at
  end

  def recovered?
    ActiveRecord::Base.connection.reconnect!
    true
  rescue Mysql2::Error
    false
  end

  # Called in an interrupt. (Ctrl-C)
  def manual_stop!
    exit 1 if stopping? # rubocop:disable Rails/Exit
    stop!
    STDOUT.puts 'Press Ctrl-C again to stop immediately.'
  end

  def process(delivery_info, metadata, payload)
    Message.new(self, delivery_info, metadata, payload).process
  end
end
