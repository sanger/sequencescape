# frozen_string_literal: true
class Event < ApplicationRecord # rubocop:todo Style/Documentation
  include Uuid::Uuidable

  self.per_page = 500
  belongs_to :eventful, polymorphic: true
  after_create :update_request, if: :request?

  scope :family_pass_and_fail, -> { where(family: %w[pass fail]).order(id: :desc) }
  scope :npg_events, ->(request_id) { where(created_by: 'npg', eventful_id: request_id) }

  def request?
    eventful.is_a?(Request)
  end

  def request
    eventful if request?
  end

  private

  include Event::RequestDescriptorUpdateEvent

  def update_request
    if family == 'fail' && request.may_evented_fail?
      request.evented_fail!
    elsif family == 'pass' && request.may_evented_pass?
      request.evented_pass!
    end
  end
end
