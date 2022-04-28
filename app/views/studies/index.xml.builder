# frozen_string_literal: true
xml.instruct!
xml.studies(type: 'array') do
  @studies.each do |study|
    xml.study do
      xml.id study.id
      xml.name study.name
    end
  end
end
