# frozen_string_literal: true

# Tube comments follow a similar proxy pattern to plate comments
class Tube::CommentsProxy
  attr_reader :comment_assn
  delegate_missing_to :comment_assn

  def initialize(tube)
    request_ids = tube.requests_as_source.pluck(:id).presence ||
                  Aliquot.where(receptacle_id: tube).where.not(request_id: nil).distinct.pluck(:request_id)
    @comment_assn = Comment.for_asset_and_requests(tube, request_ids)
  end

  # By default rails treats sizes for grouped queries different to sizes
  # for ungrouped queries. Unfortunately plates could end up performing either.
  # Grouped return a hash, for which we want the length
  # otherwise we get an integer
  # We need to urgently revisit this, as this solution is horrible.
  # Adding to the horrible: The :all passed in to the super is to address a
  # rails bug with count and custom selects.
  def size(*args)
    s = super
    s.try(:length) || s
  end

  def count(*_args)
    s = super(:all)
    s.try(:length) || s
  end
end
