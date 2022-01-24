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

  def resend
    Warren.handler << Warren::Message::Short.new(self)
  end
end
