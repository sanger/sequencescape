# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015 Genome Research Ltd.

module SampleManifest::Headers
  def self.valid?(name)
    METADATA_ATTRIBUTES_TO_CSV_COLUMNS.has_value?(name) || CORE_FIELDS.include?(name)
  end

  def self.renamed(h)
    RENAMED[h] || h
  end

  # If a field name changes (Such as when it changes from optional to required)
  # remap it here to preserve compatibility with older manifests
  RENAMED = {
    'DONOR ID (required for cancer samples)' => 'DONOR ID (required for EGA)',
    'PHENOTYPE' => 'PHENOTYPE (required for EGA)'
  }

  # Used in a number of places, pulled out as not immediately obvious
  TAG_GROUP_FIELD = 'TAG GROUP'
  TAG2_GROUP_FIELD = 'TAG2 GROUP (Fill in for dual Index Only)'
  TAG2_INDEX_FIELD = 'TAG2 INDEX (Fill in for dual Index Only)'

  CORE_FIELDS = [
    'SANGER PLATE ID',
    'SANGER TUBE ID',
    'WELL',
    'SANGER SAMPLE ID',
    'IS SAMPLE A CONTROL?',
    'IS RE-SUBMITTED SAMPLE?',
    TAG_GROUP_FIELD,
    'TAG INDEX',
    TAG2_GROUP_FIELD,
    TAG2_INDEX_FIELD,
    'LIBRARY TYPE',
    'INSERT SIZE FROM',
    'INSERT SIZE TO'
  ]

  METADATA_ATTRIBUTES_TO_CSV_COLUMNS = {
    cohort: 'COHORT',
    gender: 'GENDER',
    father: 'FATHER (optional)',
    mother: 'MOTHER (optional)',
    sibling: 'SIBLING (optional)',
    country_of_origin: 'COUNTRY OF ORIGIN',
    geographical_region: 'GEOGRAPHICAL REGION',
    ethnicity: 'ETHNICITY',
    dna_source: 'DNA SOURCE',
    date_of_sample_collection: 'DATE OF SAMPLE COLLECTION (MM/YY or YYYY only)',
    date_of_sample_extraction: 'DATE OF DNA EXTRACTION (MM/YY or YYYY only)',
    sample_extraction_method: 'DNA EXTRACTION METHOD',
    sample_purified: 'SAMPLE PURIFIED?',
    purification_method: 'PURIFICATION METHOD',
    concentration: 'CONC. (ng/ul)',
    concentration_determined_by: 'CONCENTRATION DETERMINED BY',
    sample_taxon_id: 'TAXON ID',
    sample_description: 'SAMPLE DESCRIPTION',
    accession_number_from_manifest: 'SAMPLE ACCESSION NUMBER (optional)',
    sample_sra_hold: 'SAMPLE VISIBILITY',
    sample_type: 'SAMPLE TYPE',
    volume: 'VOLUME (ul)',
    sample_storage_conditions: 'DNA STORAGE CONDITIONS',
    supplier_name: 'SUPPLIER SAMPLE NAME',
    gc_content: 'GC CONTENT',
    sample_public_name: 'PUBLIC NAME',
    sample_common_name: 'COMMON NAME',
    sample_strain_att: 'STRAIN',
    donor_id: 'DONOR ID (required for EGA)',
    phenotype: 'PHENOTYPE (required for EGA)',
    genotype: 'GENOTYPE',
    age: 'AGE (with units)',
    developmental_stage: 'Developmental stage',
    cell_type: 'Cell Type',
    disease_state: 'Disease State',
    compound: 'Compound',
    dose: 'Dose',
    immunoprecipitate: 'Immunoprecipitate',
    growth_condition: 'Growth condition',
    rnai: 'RNAi',
    organism_part: 'Organism part',
    time_point: 'Time Point',
    treatment: 'Treatment',
    subject: 'Subject',
    disease: 'Disease',
    reference_genome_name: 'REFERENCE GENOME'
  }
end
