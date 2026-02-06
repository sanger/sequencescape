# frozen_string_literal: true

require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  context 'Project' do
    should validate_presence_of :name

    context '#metadata' do
      setup { @project = Project.new name: "Project : #{Time.zone.now}" }

      should 'require cost-code and project funding model' do
        assert_equal false, @project.project_metadata.valid?, 'Validation not working'
        assert_equal false, @project.valid?, 'Validation not delegating'
        assert_equal false, @project.save, 'Save behaving badly'
        assert_includes @project.errors.full_messages, "Project metadata project cost code can't be blank"
      end

      should 'squishify the name before validation' do
        @project.name = '  Test  Project  '
        @project.valid?

        assert_equal 'Test Project', @project.name
      end
    end
  end
end
