class Messenger < ActiveRecord::Base

  belongs_to :target, :polymorphic => true
  validates_presence_of :target, :root, :template

  def shoot
    raise StandardErrror, "Hey, don't shoot the messenger"
  end

  def render_class
    "Api::Messages::#{template}".constantize
  end

  def routing_key
    "#{Rails.env}.message.#{root}.#{id}"
  end

  def as_json(options = {})
    { root => render_class.to_hash(target),
      'lims' => 'SEQUENCESCAPE' }
  end

end
