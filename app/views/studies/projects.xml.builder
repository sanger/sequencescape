xml.instruct!
if @exclude_nested_resource
  xml.projects({type: 'array'}) do |projects|
    @study.projects.each do |p|
      projects.project do |project|
        project.id p.id
      end
    end
  end
end
