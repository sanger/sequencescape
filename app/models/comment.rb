# frozen_string_literal: true
# A comment can be assigned to any commentable record.
class Comment < ApplicationRecord
  # include Uuid::Uuidable
  belongs_to :commentable, polymorphic: true, optional: false
  has_many :comments, as: :commentable
  belongs_to :user

  # @!attribute title
  #   @return [String] A short string, best used to identify the comment source.
  # @!attribute key
  #   @return [String] Longer text containing the main body of the comment

  after_create :trigger_commentable_callback

  scope :include_uuid, -> { all }

  # Caution, only works for a single class
  def self.counts_for(commentables)
    where(commentable: commentables).group(:commentable_id).count
  end

  #
  # We don't want to load comments upfront, as it can result in a lot of data
  # in some cases. However, we do want to display counts. However when it
  # comes to requests, there are three places we may wish to look:
  # - The request itself
  # - The receptacle (source receptacle)
  # - The labware associated with the receptacle
  # Rather than having three separate columns, we instead reduce it down to
  # a single place. This method lets us aggregate those counts
  # @param requests [Array<Request>] Requests to get counts for. Preferably with preloaded assets
  #
  # @return [Hash] Hash of counts indexed by request_id
  #
  def self.counts_for_requests(requests) # rubocop:todo Metrics/AbcSize
    all_commentables = requests.flat_map { |request| [request, request.try(:asset), request.try(:asset).try(:labware)] }
    counts = where(commentable: all_commentables.compact).group(:commentable_type, :commentable_id).count

    requests.each_with_object({}) do |request, counter_cache|
      request_count = counts.fetch(['Request', request.id], 0)
      receptacle_count = counts.fetch(['Receptacle', request.try(:asset_id)], 0)
      labware_count = counts.fetch(['Labware', request.try(:asset).try(:labware_id)], 0)
      counter_cache[request.id] = request_count + receptacle_count + labware_count
    end
  end

  private

  ##
  # We add the comments to each submission to ensure that are available for all the requests.
  # At time of writing, submissions add comments to each request, so there are a lot of comments
  # getting created here. We should consider either storing comments on submissions, orders,
  # or having a many-to-many relationship.
  def trigger_commentable_callback
    commentable.try(:after_comment_addition, self)
  end
end
