# frozen_string_literal: true
class Failure < ApplicationRecord
  belongs_to :failable, polymorphic: true
  after_create :notify_remote

  def notify_remote
    nil unless notify_remote?
      # Send event to Studies here
    
  end
end
