class Messenger < ApplicationRecord
  belongs_to :target, ->(messenger) { includes(messenger.render_class.includes) }, polymorphic: true
  validates_presence_of :target, :root, :template
  broadcast_via_warren

  def shoot
    raise StandardErrror, "Hey, don't shoot the messenger"
  end

  def render_class
    "Api::Messages::#{template}".constantize
  end

  def routing_key
    "#{Rails.env}.message.#{root}.#{id}"
  end

  def as_json(_options = {})
    { root => render_class.to_hash(target),
      'lims' => configatron.amqp.lims_id! }
  end

  def resend
    broadcast
  end
end
