module SampleManifestExcel
  module Download

	  module ColumnHelper
	    extend ActiveSupport::Concern

	    module ClassMethods

	      def   set_columns (names)
	        _column_names = self.respond_to?(:column_names) ? self.column_names : []
	          define_singleton_method :column_names do
	            _column_names + names
	          end
	      end

	    end

	  end

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

	  module Default
	    extend ActiveSupport::Concern

	    include ColumnHelper

	    included do
	      set_columns [:sanger_sample_id,:supplier_sample_name, :cohort, :volume, :conc, :gender, :country_of_origin, :geographical_region, :ethnicity, :dna_source, :date_of_sample_collection, :date_of_dna_extraction, :is_sample_a_control?, :is_re_submitted_sample?, :dna_extraction_method, :sample_purified?, :purification_method, :concentration_determined_by, :dna_storage_conditions, :mother, :father, :sibling, :gc_content, :public_name, :taxon_id, :common_name, :sample_description, :strain, :sample_visibility, :sample_type, :sample_accession_number, :donor_id, :phenotype]
	    end

	  end

	  module Full

	    extend ActiveSupport::Concern

	    include ColumnHelper

	    included do
	      set_columns [:sanger_sample_id, :supplier_sample_name, :cohort, :volume, :conc, :gender, :country_of_origin, :geographical_region, :ethnicity, :dna_source, :date_of_sample_collection, :date_of_dna_extraction, :is_sample_a_control?, :is_re_submitted_sample?, :dna_extraction_method, :sample_purified?, :purification_method, :concentration_determined_by, :dna_storage_conditions, :mother, :father, :sibling, :gc_content, :public_name, :taxon_id, :common_name, :sample_description, :strain, :sample_visibility, :sample_type, :genotype, :phenotype, :age, :developmental_stage, :cell_type, :disease_state, :compound, :dose, :immunoprecipitate, :growth_condition, :rnai, :rnai_2, :organism_part, :time_point, :treatment, :subject, :disease, :sample_accession_number, :donor_id_2]
	    end

	  end

	  module Rnachip

	    extend ActiveSupport::Concern

	    include ColumnHelper

	    included do
    		set_columns [ :sanger_sample_id, :supplier_sample_name, :cohort, :volume, :conc, :gender, :dna_source, :gc_content, :public_name, :taxon_id, :common_name, :sample_description, :strain, :sample_visibility, :sample_type, :phenotype, :developmental_stage, :cell_type, :immunoprecipitate, :organism_part, :sample_accession_number, :donor_id_2]
	    end

	  end

	  module Multiplexed

	    extend ActiveSupport::Concern

	    include ColumnHelper

	    included do
    		set_columns [ :tag_group, :tag_index, :tag2_group, :tag2_index, :library_type, :insert_size_from, :insert_size_to]
	    end

	  end
  end
end