xml.instruct!
xml.studies(type: 'array') {
  @studies.each do |study|
    xml.study {
      xml.id study.id
      xml.name study.name
    }
  end
}
