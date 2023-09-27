# frozen_string_literal: true

require 'syslog/logger'
require 'ostruct'
require 'psd_formatter'

class PsdFormatter < Syslog::Logger::Formatter # rubocop:todo Style/Documentation
  LINE_FORMAT = "(thread-%s) [%s] %5s -- : %s\n".freeze

  def initialize(deployment_info)
    # below line is included because it was unknown whether
    # deployment_info is a Hash, an OpenStruct or a Struct - this makes them all a hash
    info = deployment_info.to_h
    @app_tag = [info[:name], info[:version], info[:environment]].compact.join(':').freeze
    super()
  end

  def call(severity, _timestamp, _progname, msg)
    thread_id = Thread.current.object_id
    format(LINE_FORMAT, thread_id, @app_tag, format_severity(severity), msg)
  end

  private

  # Severity label for logging (max 5 chars).
  SEV_LABEL = %w[DEBUG INFO WARN ERROR FATAL ANY].each(&:freeze).freeze

  def format_severity(severity)
    severity.is_a?(Integer) ? SEV_LABEL[severity] || 'ANY' : severity
  end
end
