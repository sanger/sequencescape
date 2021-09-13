# frozen_string_literal: true
xml.instruct!
if @exclude_nested_resource
  xml.projects({ type: 'array' }) do |projects|
    @study.projects.each { |p| projects.project { |project| project.id p.id } }
  end
end
