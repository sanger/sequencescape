class Api::StudyIO < Api::Base
  renders_model(::Study)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id)
  map_attribute_to_json_attribute(:name)
  map_attribute_to_json_attribute(:ethically_approved)
  map_attribute_to_json_attribute(:state)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)
  extra_json_attributes do |object, json_attributes|
     json_attributes["abbreviation"] = object.abbreviation
   end

  with_association(:study_metadata) do
    with_association(:faculty_sponsor, :lookup_by => :name) do
      map_attribute_to_json_attribute(:name, 'sac_sponsor')
    end
    
    with_association(:reference_genome, :lookup_by => :name) do
      map_attribute_to_json_attribute(:name, 'reference_genome')
    end
    map_attribute_to_json_attribute(:study_ebi_accession_number, 'accession_number')
    map_attribute_to_json_attribute(:study_description         , 'description')
    map_attribute_to_json_attribute(:study_abstract            , 'abstract')
    with_association(:study_type, :lookup_by => :name) do
      map_attribute_to_json_attribute(:name                    , 'study_type')
    end
    
    map_attribute_to_json_attribute(:study_project_id, 'ena_project_id')
    map_attribute_to_json_attribute(:study_study_title, 'study_title')
    map_attribute_to_json_attribute(:study_sra_hold, 'study_visibility')

    map_attribute_to_json_attribute(:contaminated_human_dna)
    map_attribute_to_json_attribute(:contains_human_dna)
    map_attribute_to_json_attribute(:commercially_available)
    with_association(:data_release_study_type, :lookup_by => :name ) do
      map_attribute_to_json_attribute(:name                    , 'data_release_sort_of_study')
    end

    map_attribute_to_json_attribute(:data_release_strategy)

  end

  self.related_resources = [ :samples, :projects ]
end
