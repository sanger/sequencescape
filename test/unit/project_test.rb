# frozen_string_literal: true

require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  context 'Project' do
    should validate_presence_of :name

    context '#metadata' do
      setup do
        @project = Project.new name: "Project : #{Time.now}"
      end

      should 'require cost-code and project funding model' do
        assert_equal false, @project.project_metadata.valid?, 'Validation not working'
        assert_equal false, @project.valid?, 'Validation not delegating'
        assert_equal false, @project.save, 'Save behaving badly'
        assert @project.errors.full_messages.include?("Project metadata project cost code can't be blank")
      end
    end
  end
end
