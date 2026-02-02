# frozen_string_literal: true
# Messengers handle passing a target into a message template
# for rendering warehouse messages
class Messenger < ApplicationRecord
  belongs_to :target, ->(messenger) { includes(messenger.render_class.includes) }, polymorphic: true
  validates :target, :root, :template, presence: true
  broadcast_with_warren

  def render_class
    "Api::Messages::#{template}".constantize
  end

  def routing_key
    "message.#{root}.#{id}"
  end

  def as_json(_options = {})
    { root => render_class.to_hash(target), 'lims' => configatron.amqp.lims_id! }
  end

  def template
    # Replace IO with Io to match the class name
    # This is a consequence of the zeitwerk renaming for the message modules from IO to Io
    # This ensures that the correct class is loaded for historical messages
    read_attribute(:template).gsub(/IO$/, 'Io')
  end

  def resend
    Warren.handler << Warren::Message::Short.new(self)
  end
end
