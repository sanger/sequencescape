module SampleManifestExcel
  module Download
    class Full < Base

    	def columns_names
    		type_specific_column_names + full_columns_names
    	end

    	def full_columns_names
				[:sanger_sample_id, :supplier_sample_name, :cohort, :volume, :conc, :gender, :country_of_origin, :geographical_region, :ethnicity, :dna_source, :date_of_sample_collection, :date_of_dna_extraction, :is_sample_a_control?, :is_re_submitted_sample?, :dna_extraction_method, :sample_purified?, :purification_method, :concentration_determined_by, :dna_storage_conditions, :mother, :father, :sibling, :gc_content, :public_name, :taxon_id, :common_name, :sample_description, :strain, :sample_visibility, :sample_type, :genotype, :phenotype, :age, :developmental_stage, :cell_type, :disease_state, :compound, :dose, :immunoprecipitate, :growth_condition, :rnai, :rnai_2, :organism_part, :time_point, :treatment, :subject, :disease, :sample_accession_number, :donor_id_2]
    	end
    end
  end
end