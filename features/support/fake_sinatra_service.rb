# We're going to be using mongrel but it outputs stuff to STDERR.  Luckily it doesn't reference the
# top-level constant, so we can override it here!
require 'mongrel'
class Mongrel::HttpServer
  const_set(:STDERR, Object.new.tap do |null_outputter|
    def null_outputter.puts(*args, &block)
      # Do nothing, we don't care
    end
  end) unless const_defined?(:STDERR)
end

class FakeSinatraService
  include Singleton

  # Ensures that ports are assigned dynamically and that they are random, reducing the chances of
  # clashes both between the fake services in this test run, and between the fake services across
  # test runs.
  def self.take_next_port
    if @ports.nil?
      initial_port = 16000 + (ENV['TEST_ENV_NUMBER'].to_i * 1000)  # Base it at some sane port
      initial_port += (($$ % 100) * 10)  # Use pid and use a range
      @ports       = (1..100).to_a.shuffle.map { |p| initial_port + p }
    end
    @ports.shift
  end

  attr_reader :port
  attr_reader :host

  def initialize(*args, &block)
    @host, @port = 'localhost', self.class.take_next_port
  end

  def self.install_hooks(target, tags)
    service = self
    target.instance_eval do
      # Ensure that, if we're running in a javascript environment, that the browser has been launched
      # before we start our service.  This ensures that the listening port is not inherited by the fork
      # within the Selenium driver.
      Before(tags) do |scenario|
        Capybara.current_session.driver.browser if Capybara.current_driver == Capybara.javascript_driver
        service.instance.start!
      end
      After(tags)  { |scenario| service.instance.finish! }
    end
  end

  def start!
    raise StandardError, "Cannot start up multiple instances of #{self.class.name}" unless @thread.nil?

    start_sinatra do |thread|
      @thread = thread
      wait_for_sinatra_to_startup!
    end
  end

  def finish!
    kill_running_sinatra
    @thread.join
    clear
  ensure
    @thread = nil
  end

private

  def clear

  end

  def start_sinatra(&block)
    thread = Thread.new do
      # The effort you have to go through to silence Sinatra/WEBrick!
      logger       = Logger.new(STDERR)
      logger.level = Logger::FATAL

      service.run!(:host => @host, :port => @port, :webrick => { :Logger => logger, :AccessLog => [] })
    end
    yield(thread)
  end

  def kill_running_sinatra
    Net::HTTP.get(URI.parse("http://#{@host}:#{@port}/die_eat_flaming_death"))
  rescue EOFError => exception
    # This is fine, it means that Sinatra apparently died.
  rescue Errno::ECONNREFUSED => exception
    # This is probably fine too because it means it wasn't running in the first place!
  rescue SystemExit => exception
    # This one is probably fine to ignore too.
  end

  # We have to pause execution until Sinatra has come up.  This makes a number of attempts to
  # retrieve the root document.  If it runs out of attempts it raises an exception
  def wait_for_sinatra_to_startup!
    connect_uri = URI.parse("http://#{@host}:#{@port}/up_and_running")
    (1..200).each do |i|
      begin
        Net::HTTP.get(connect_uri)
        return
      rescue Errno::ECONNREFUSED => exception
        sleep(1)
      end
    end

    raise StandardError, "Our dummy webservice did not start up in time!"
  end

  class Base < Sinatra::Base
    # Use Mongrel as the handler as it's quicker to start than Webrick.  It might take a few seconds to
    # shutdown but Webrick takes ~30 to start so Mongrel wins out.
    HANDLER, QUIT_HANDLER = Rack::Handler.get('mongrel'), :stop

    def self.run!(options={})
      set options
      HANDLER.run(self, { :Host => bind, :Port => port, :timeout => 1 }.merge(options.fetch(:webrick, {}))) do |server|
        set :running, true
        set :quit_handler, Proc.new { server.send(QUIT_HANDLER) }
      end
    rescue Errno::EADDRINUSE => e
      raise StandardError, "== Someone is already performing on port #{port}!"
    rescue SystemExit => e
      # Ignore and continue (or rather, die).
    rescue IOError => e
      # Ignore and continue (or rather, die).
    end

    get('/up_and_running') do
      status(200)
      body('Up and running')
    end

    get('/die_eat_flaming_death') do
      Object.tap do |handler|
        handler.instance_variable_set(:@quit, settings.method(:quit_handler))

        def handler.each(&block)
          yield('done')
        end

        def handler.close
          @quit.call
        end
      end
    end
  end
end unless self.class.const_defined?(:FakeSinatraService)

