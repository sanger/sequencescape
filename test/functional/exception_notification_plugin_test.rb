require "test_helper"

class MyBrokenController < ActionController::Base
  include ExceptionNotifiable
  alias_method(:rescue_action, :rescue_action_in_public)

  # This method is purposely set up to fail and by having the @request member variable
  # it triggers the bug in the exception notification code.
  def my_broken_action
    @request = 'This is not the request you are looking for'
    raise StandardError, "I'm so broken"
  end
end

# This is an extremely simple test in that it just makes sure that the exception notification
# code doesn't blow up in my face.  With the default implementation of the exception notification
# plugin the @request in the controller above would be used, which would cause all kinds of
# problems when rendering the email.  With the fixes in place it shouldn't error at all.
#
# If the exception notification stuff is broken you'll see this error:
#
#   test: handling exceptions should send an email. (ExceptionNotificationPluginTest):
#   ActionView::TemplateError: undefined method `protocol' for "This is not the request you are looking for":String
#
# If it's not, you won't!
#
# For more information see: http://www.pivotaltracker.com/story/show/3554781
class ExceptionNotificationPluginTest < ActionController::TestCase
  tests MyBrokenController

  context 'handling exceptions' do
    setup do
      get :my_broken_action
    end

    teardown do
      ActionMailer::Base.deliveries.clear
    end

    should 'send an email' do
      assert_sent_email
    end
  end
end
