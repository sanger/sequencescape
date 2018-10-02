# frozen_string_literal: true

require 'syslog/logger'
require 'ostruct'

class PsdFormatter < Syslog::Logger::Formatter
  LINE_FORMAT = "(thread-%s) [%s] %5s -- : %s\n".freeze

  def initialize(deployment_info)
    info = OpenStruct.new(deployment_info)
    @app_tag = [info.name, info.version, info.environment].compact.join(':').freeze
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
    if severity.is_a?(Integer)
      SEV_LABEL[severity] || 'ANY'
    else
      severity
    end
  end
end
