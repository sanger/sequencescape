# frozen_string_literal: true

require 'test_helper'

class ApiApplicationTest < ActiveSupport::TestCase
  should validate_presence_of :name
  should validate_presence_of :contact
  should validate_presence_of :privilege

  context '#create' do
    setup { @app = ApiApplication.create(name: 'test') }

    should 'automatically generate a key if no present' do
      @app = ApiApplication.create

      assert_predicate @app.key, :present?, 'No key generated'
      assert_operator @app.key.length, :>=, 20, 'Key too short'
    end

    should 'not generate a key if present' do
      @app = ApiApplication.create(key: 'test')

      assert_predicate @app.key, :present?
      assert_equal 'test', @app.key
    end
  end
end
