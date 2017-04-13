xml.instruct!
xml.studies({type: 'array'}) do |studies|
  @project.studies.each do |p|
    studies.study do |study|
      study.id p.id
      study.name p.name
    end
  end
end
