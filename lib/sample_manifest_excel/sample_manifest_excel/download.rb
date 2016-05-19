module SampleManifestExcel

	#A download takes data of all possible columns used in various excel sample manifests
	#and creates an excel sample manifest file with the  columns, required for particular type
	#of sample manifest, values, data validation and conditional formatting.
	#
	#For now 7 types of excel sample manifests can be created:
	#- plate default,
	#- tube default,
	#- multiplexed library default,
	#- plate full,
	#- tube full,
	#- plate RNAChIP,
	#- tube RNAChIP.
	#

  module Download

	  module ColumnHelper
	    extend ActiveSupport::Concern

	    module ClassMethods

	      def set_columns (names)
	        _column_names = self.respond_to?(:column_names) ? self.column_names : []
	          define_singleton_method :column_names do
	            _column_names + names
	          end
	      end

	    end

	  end

	  #Plate has specific columns names required for plate sample manifests.

	  module Plate
	    extend ActiveSupport::Concern

	    include ColumnHelper

	    included do
	    	set_columns [:sanger_plate_id, :well]
	    end

	    def type
	    	'Plates'
	    end
    end

	  #Tube has specific columns names required for tube sample manifests.

    module Tube
	    extend ActiveSupport::Concern

	    include ColumnHelper

	    included do
	    	set_columns [:sanger_tube_id]
	    end

	    def type
	    	'Tubes'
	    end
    end

	  #Default has specific columns names required for default sample manifests.

	  module Default
	    extend ActiveSupport::Concern

	    include ColumnHelper

	    included do
	      set_columns [:sanger_sample_id,:supplier_sample_name, :cohort, :volume, :conc, :gender, :country_of_origin, :geographical_region, :ethnicity, :dna_source, :date_of_sample_collection, :date_of_dna_extraction, :is_sample_a_control?, :is_re_submitted_sample?, :dna_extraction_method, :sample_purified?, :purification_method, :concentration_determined_by, :dna_storage_conditions, :mother, :father, :sibling, :gc_content, :public_name, :taxon_id, :common_name, :sample_description, :strain, :sample_visibility, :sample_type, :sample_accession_number, :donor_id, :phenotype]
	    end

	  end

	  #Full has specific columns names required for full sample manifests.

	  module Full

	    extend ActiveSupport::Concern

	    include ColumnHelper

	    included do
	      set_columns [:sanger_sample_id, :supplier_sample_name, :cohort, :volume, :conc, :gender, :country_of_origin, :geographical_region, :ethnicity, :dna_source, :date_of_sample_collection, :date_of_dna_extraction, :is_sample_a_control?, :is_re_submitted_sample?, :dna_extraction_method, :sample_purified?, :purification_method, :concentration_determined_by, :dna_storage_conditions, :mother, :father, :sibling, :gc_content, :public_name, :taxon_id, :common_name, :sample_description, :strain, :sample_visibility, :sample_type, :genotype, :phenotype, :age, :developmental_stage, :cell_type, :disease_state, :compound, :dose, :immunoprecipitate, :growth_condition, :rnai, :rnai_2, :organism_part, :time_point, :treatment, :subject, :disease, :sample_accession_number, :donor_id_2]
	    end

	  end

	  #Rnachip has specific columns names required for RNAChIP sample manifests.

	  module Rnachip

	    extend ActiveSupport::Concern

	    include ColumnHelper

	    included do
    		set_columns [ :sanger_sample_id, :supplier_sample_name, :cohort, :volume, :conc, :gender, :dna_source, :gc_content, :public_name, :taxon_id, :common_name, :sample_description, :strain, :sample_visibility, :sample_type, :phenotype, :developmental_stage, :cell_type, :immunoprecipitate, :organism_part, :sample_accession_number, :donor_id_2]
	    end

	  end

	  #Multiplexed has specific columns names required for multiplexed libraries sample manifests.

	  module Multiplexed

	    extend ActiveSupport::Concern

	    include ColumnHelper

	    included do
    		set_columns [ :tag_group, :tag_index, :tag2_group, :tag2_index, :library_type, :insert_size_from, :insert_size_to]
	    end

	  end
  end
end