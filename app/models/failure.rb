class Failure < ActiveRecord::Base
  belongs_to :failable, :polymorphic => true
  after_create :notify_remote

  def notify_remote
    if self.notify_remote?
      #Send event to Studies here
    end
  end
end
