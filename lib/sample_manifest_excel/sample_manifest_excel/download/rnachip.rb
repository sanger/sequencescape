module SampleManifestExcel
  module Download
    class Rnachip < Base

    	def columns_names
    		type_specific_column_names + rnachip_columns_names
    	end

    	def rnachip_columns_names
    		[ :sanger_sample_id, :supplier_sample_name, :cohort, :volume, :conc, :gender, :dna_source, :gc_content, :public_name, :taxon_id, :common_name, :sample_description, :strain, :sample_visibility, :sample_type, :phenotype, :developmental_stage, :cell_type, :immunoprecipitate, :organism_part, :sample_accession_number, :donor_id_2]
    	end
    end
  end
end