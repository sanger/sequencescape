#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014,2015 Genome Research Ltd.
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
      'lims' => configatron.amqp.lims_id! }
  end

  def resend
    AmqpObserver.instance << self
  end

end
