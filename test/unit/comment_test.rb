require "test_helper"

class CommentTest < ActiveSupport::TestCase
  context "A comment" do
    should_belong_to :commentable, :user
    should_have_many :comments
  end

end
