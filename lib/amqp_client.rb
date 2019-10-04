# frozen_string_literal: true

APP_PATH = File.expand_path('../config/application', __dir__)

require 'daemons'
require 'bunny'
require 'rails'
require './lib/postman'
require './lib/postman/channel'

# Sets up a pool of workers to process the rebroadcast queues
# This class handles the extraction of command-line parameters
# and their passing to the {WorkerPool}
# @example Basic usage
# `bundle exec bin/amqp_client start`
class AmqpClient
  APP_NAME = 'queue_broadcast_consumer'
  DEFAULT_WORKERS = 2
  DEFAULT_PID_DIR = './tmp/pids'

  NotImplimented = Class.new(StandardError)

  # Spawns and daemonizes multiple postmen.
  class WorkerPool
    #
    # Create a {Postman} work pool. Typically these are built through the
    # {AmqpClient} and run in daemonized processes.
    # @param app_name [String] The name of the application. Corresponds to the subscriptions config in `config/warren.yml`
    # @param pid_dir [String] Path to the pid directory
    # @param workers [Integer] Number of workers to spawn on daemonization
    # @param instance [nil,Integer] Index of the particular worker to start/stop [Optional]
    # @param config [Hash] A configuration object, loaded from `config/warren.yml` by default
    #
    # @return [type] [description]
    def initialize(app_name, pid_dir, workers, instance, config = nil)
      @app_name = app_name
      @pid_dir = pid_dir
      @worker_count = workers
      @instance = instance
      @config = config
    end

    #
    # Number of workers to spawn on daemonization
    #
    # @return [Integer] Number of workers that will be spawned
    def worker_count
      @instance ? 1 : @worker_count
    end

    #
    # Spawn `worker_count` daemonized workers
    def start!
      worker_count.times do |i|
        daemon(@instance || i)
      end
    end

    # We preload our application before forking!
    def load_rails!
      $stdout.puts 'Loading application...'
      require_relative '../config/environment'
      # We need to disconnect before forking.
      $stdout.puts 'Registering queues'
      register_deadletters_queues
      ActiveRecord::Base.connection.disconnect!
      $stdout.puts 'Loaded!'
    end

    #
    # The queue and exchange configuration for this pool
    #
    # @return [Hash] Configuration object, usually loaded from `config/warren.yml`
    def config
      @config ||= Rails.application.config.warren.symbolize_keys
    end

    #
    # Spawn a new postman in the current process
    # Usually generated automatically in separate daemonized processes via {#start!}
    #
    # @return [Void] Blocking. Will not return until the {Postman} is terminated
    def spawn_postman
      client = Bunny.new(server_config)
      main_exchange = Postman::Channel.new(client: client, config: queue_config)
      Postman.new(
        client: client,
        main_exchange: main_exchange
      ).run!
    end

    #
    # Ensures the deadletter queues and exchanges are registered.
    #
    # @return [Void]
    def register_deadletters_queues
      client = Bunny.new(server_config)
      main_exchange = Postman::Channel.new(client: client, config: queue_config('.deadletters'))
      client.start
      main_exchange.activate!
      client.stop
    end

    private

    #
    # Spawn a daemonized {Postman} of index `instance`
    # @param instance [String] The worker we are spawning
    #
    # @return [Void]
    def daemon(instance)
      Daemons.run_proc(server_name(instance), multiple: multiple, dir: @pid_dir, backtrace: true, log_output: true) do
        ActiveRecord::Base.establish_connection # We reconnect to the database after the fork.
        spawn_postman
      end
    end

    # Returns true unless we are spawning a specific instance
    def multiple
      @instance.nil?
    end

    def server_config
      config.dig(:config, 'server').deep_symbolize_keys || {}
    end

    def queue_config(config_suffix = nil)
      config.dig(:subscriptions, "#{@app_name}#{config_suffix}").deep_symbolize_keys
    end

    #
    # Generates a process name
    # @param i [Integer] Worker index to generate a name for
    #
    # @return [String] Name for the worker
    def server_name(worker_index)
      "#{@app_name}_num#{worker_index}"
    end
  end

  attr_reader :workers, :instance, :pid_dir

  def initialize(args)
    @action = args.first
    # TODO: DRY this out
    self.workers = args.detect { |arg| arg =~ /\Aw[0-9]+\z/ }
    self.instance = args.detect { |arg| arg =~ /\Ai[0-9]+\z/ }
    self.pid_dir = args.detect { |arg| arg =~ /\Apid_dir=.+\z/ }
  end

  # TODO: DRY this out
  def workers=(workers_config)
    @workers = if workers_config.nil?
                 DEFAULT_WORKERS
               else
                 workers_config.slice(1, workers_config.length).to_i
               end
  end

  def pid_dir=(pid_dir_config)
    @pid_dir = if pid_dir_config.nil?
                 DEFAULT_PID_DIR
               else
                 /\Apid_dir=(.+)\z/.match(pid_dir_config)[1]
               end
  end

  def instance=(instance_config)
    @instance = instance_config.slice(1, instance_config.length).to_i if instance_config.present?
  end

  def worker_pool
    @worker_pool ||= WorkerPool.new(APP_NAME, pid_dir, worker_count, instance)
  end

  def run
    worker_pool.load_rails! if preload_required?
    worker_pool.start!
  end

  # Only bother loading rails if necessary
  def preload_required?
    %w[start restart reload run].include?(@action)
  end

  # If we're not daemonising we limit ourselves to one worker.
  # Otherwise we end up running our various workers in series
  # which isn't really what we want.
  def worker_count
    @action == 'run' ? 1 : workers
  end
end
