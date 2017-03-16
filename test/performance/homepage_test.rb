# run export JRUBY_OPTS="-Xlaunch.inproc=false --profile.api" before the performance tests
# use RUBYOPT='-W0' to turn off the warnings

require 'test_helper'
require 'rails/performance_test_help'

class HomepageTest < ActionDispatch::PerformanceTest
  def setup
    user = create :user
    post '/login', 'login' => user.login, 'password' => user.password
  end

  test 'homepage' do
    get '/'
  end
end
