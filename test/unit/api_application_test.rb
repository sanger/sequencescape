#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
require "test_helper"

class ApiApplicationTest < ActiveSupport::TestCase
  context "#create" do

    should_validate_presence_of :name, :contact, :privilege


    should "automatically generate a key if no present" do
      @app = ApiApplication.create()
      assert @app.key.present?, 'No key generated'
      assert @app.key.length >= 20, 'Key too short'
    end

    should "not generate a key if present" do
      @app = ApiApplication.create(:key=>'test')
      assert @app.key.present?
      assert_equal 'test', @app.key
    end


  end

end
