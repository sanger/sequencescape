xml.instruct!
xml.STUDY_SET({'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance'}) do |study_set|
  study_set.STUDY({alias: @ebi_study_data[:alias], accession: @accession_number}) do |study|
    study.DESCRIPTOR do |descriptor|
      descriptor.STUDY_TITLE  @ebi_study_data[:study_title]
      descriptor.STUDY_DESCRIPTION @ebi_study_data[:description]
      descriptor.CENTER_PROJECT_NAME  @ebi_study_data[:center_study_name]
      descriptor.CENTER_NAME  @ebi_study_data[:center_name]
      descriptor.STUDY_ABSTRACT  @ebi_study_data[:study_abstract]
      if @ebi_study_data[:study_id]
        descriptor.PROJECT_ID  @ebi_study_data[:study_id]
      else
        descriptor.PROJECT_ID  "0"
      end
      descriptor.STUDY_TYPE({existing_study_type: @ebi_study_data[:existing_study_type]})
    end
  end
end

