# frozen_string_literal: true
class Failure < ApplicationRecord # rubocop:todo Style/Documentation
  belongs_to :failable, polymorphic: true
  after_create :notify_remote

  def notify_remote
    if notify_remote?
      # Send event to Studies here
    end
  end
end
