class Event < ApplicationRecord
  include Uuid::Uuidable

  self.per_page = 500
  belongs_to :eventful, polymorphic: true
  after_create :update_request

  scope :family_pass_and_fail, -> { where(family: ['pass', 'fail']).order(id: :desc) }
  scope :npg_events, ->(request_id) { where(created_by: 'npg', eventful_id: request_id) }

  def request?
    eventful.is_a?(Request)
  end

  private

  include Event::AssetDescriptorUpdateEvent
  include Event::RequestDescriptorUpdateEvent

  def update_request
    if request?
      request = eventful
      if family == 'fail' && request.may_fail?
        request.fail!
      elsif family == 'pass' && request.may_pass?
        request.pass!
      end
    end
  end
end
