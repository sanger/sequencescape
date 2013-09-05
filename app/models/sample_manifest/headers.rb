module SampleManifest::Headers

  def self.valid?(name)
    METADATA_ATTRIBUTES_TO_CSV_COLUMNS.has_value?(name) || CORE_FIELDS.include?(name)
  end

  def self.renamed(h)
    RENAMED[h]||h
  end

  # If a field name changes (Such as when it changes from optional to required)
  # remap it here to preserve compatibility with older manifests
  RENAMED = {
    'DONOR ID (required for cancer samples)'=>'DONOR ID (required for EGA)',
    'PHENOTYPE' => 'PHENOTYPE (required for EGA)'
  }


  CORE_FIELDS = [
    'SANGER PLATE ID',
    'SANGER TUBE ID',
    'WELL',
    'SANGER SAMPLE ID',
    'IS SAMPLE A CONTROL?',
    'IS RE-SUBMITTED SAMPLE?'
  ]

  METADATA_ATTRIBUTES_TO_CSV_COLUMNS = {
    :cohort                         => 'COHORT',
    :gender                         => 'GENDER',
    :father                         => 'FATHER (optional)',
    :mother                         => 'MOTHER (optional)',
    :sibling                        => 'SIBLING (optional)',
    :country_of_origin              => 'COUNTRY OF ORIGIN',
    :geographical_region            => 'GEOGRAPHICAL REGION',
    :ethnicity                      => 'ETHNICITY',
    :dna_source                     => 'DNA SOURCE',
    :date_of_sample_collection      => 'DATE OF SAMPLE COLLECTION (MM/YY or YYYY only)',
    :date_of_sample_extraction      => 'DATE OF DNA EXTRACTION (MM/YY or YYYY only)',
    :sample_extraction_method       => 'DNA EXTRACTION METHOD',
    :sample_purified                => 'SAMPLE PURIFIED?',
    :purification_method            => 'PURIFICATION METHOD',
    :concentration                  => "CONC. (ng/ul)",
    :concentration_determined_by    => 'CONCENTRATION DETERMINED BY',
    :sample_taxon_id                => 'TAXON ID',
    :sample_description             => 'SAMPLE DESCRIPTION',
    :accession_number_from_manifest => 'SAMPLE ACCESSION NUMBER (optional)',
    :sample_sra_hold                => 'SAMPLE VISIBILITY',
    :sample_type                    => 'SAMPLE TYPE',
    :volume                         => "VOLUME (ul)",
    :sample_storage_conditions      => 'DNA STORAGE CONDITIONS',
    :supplier_name                  => 'SUPPLIER SAMPLE NAME',
    :gc_content                     => 'GC CONTENT',
    :sample_public_name             => 'PUBLIC NAME',
    :sample_common_name             => 'COMMON NAME',
    :sample_strain_att              => 'STRAIN',
    :donor_id                       => 'DONOR ID (required for EGA)',
    :phenotype                      => 'PHENOTYPE (required for EGA)',
    :genotype                       => 'GENOTYPE',
    :age                            => 'AGE (with units)',
    :developmental_stage            => 'Developmental stage',
    :cell_type                      => 'Cell Type',
    :disease_state                  => 'Disease State',
    :compound                       => 'Compound',
    :dose                           => 'Dose',
    :immunoprecipitate              => 'Immunoprecipitate',
    :growth_condition               => 'Growth condition',
    :rnai                           => 'RNAi',
    :organism_part                  => 'Organism part',
    :time_point                     => 'Time Point',
    :treatment                      => 'Treatment',
    :subject                        => 'Subject',
    :disease                        => 'Disease'
  }

end
