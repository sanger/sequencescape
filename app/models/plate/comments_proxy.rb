# frozen_string_literal: true

# Plate comments are a mess
# - You can have comments on the plate itself.
# - But 90% of the time you want comments on the requests associated with the plate
# - Except these aren't event directly associated with the plate
# - Or even the wells on the plate.
# - Instead they come from wells further upstream
# - Oh, and typically all requests in a submission have identical comments
# - But showing the same comment to the user 96 times is just confusing
# - So we have a special scope to find comments.
# - And to add them
# - And then the API chokes when it tries to display the comment count, as it doesn't
#   understand group by.
# - So we hack that
# - And then we weep every time anything changes
# - It would be vastly easier if comments just sat on submissions
# - Although even then we'd need to copy them across if work is re-requested.
class Plate::CommentsProxy
  attr_reader :plate
  delegate_missing_to :comment_assn

  def initialize(plate)
    @plate = plate
  end

  def comment_assn
    @asn ||= Comment.for_plate(plate)
  end

  ##
  # We add the comments to each submission to ensure that are available for all the requests.
  # At time of writing, submissions add comments to each request, so there are a lot of comments
  # getting created here. (The intent is to change this so requests are treated similarly to plates)
  def create!(options)
    plate.submissions.each { |s| s.add_comment(options[:description], options[:user]) }
    Comment.create!(options.merge(commentable: plate))
  end

  def create(options)
    plate.submissions.each { |s| s.add_comment(options[:description], options[:user]) }
    Comment.create(options.merge(commentable: plate))
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
    return s.length if s.respond_to?(:length)

    s
  end

  def count(*_args)
    s = super(:all)
    return s.length if s.respond_to?(:length)

    s
  end
end
