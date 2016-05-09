module SampleManifestExcel
  module Download
    class Default < Base

    	def columns_names
    		type_specific_column_names + default_columns_names
    	end

    	def default_columns_names
    		[:sanger_sample_id,:supplier_sample_name, :cohort, :volume, :conc, :gender, :country_of_origin, :geographical_region, :ethnicity, :dna_source, :date_of_sample_collection, :date_of_dna_extraction, :is_sample_a_control?, :is_re_submitted_sample?, :dna_extraction_method, :sample_purified?, :purification_method, :concentration_determined_by, :dna_storage_conditions, :mother, :father, :sibling, :gc_content, :public_name, :taxon_id, :common_name, :sample_description, :strain, :sample_visibility, :sample_type, :sample_accession_number, :donor_id, :phenotype]
    	end
    end
  end
end