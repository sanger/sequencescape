class SampleMetadata < ApplicationRecord
  GC_CONTENTS     = ['Neutral', 'High AT', 'High GC']
  GENDERS         = ['Male', 'Female', 'Mixed', 'Hermaphrodite', 'Unknown', 'Not Applicable']
  DNA_SOURCES     = ['Genomic', 'Whole Genome Amplified', 'Blood', 'Cell Line', 'Saliva', 'Brain', 'FFPE',
                     'Amniocentesis Uncultured', 'Amniocentesis Cultured', 'CVS Uncultured', 'CVS Cultured', 'Fetal Blood', 'Tissue']
  SRA_HOLD_VALUES = ['Hold', 'Public', 'Protect']

  belongs_to :sample, validate: false, autosave: false
  belongs_to :owner, validate: false, autosave: false
  include ReferenceGenome::Associations

  attr_reader :reference_genome_set_by_name
  # The spreadsheets that people upload contain various fields that could be mistyped.  Here we ensure that the
  # capitalisation of these is correct.
  REMAPPED_ATTRIBUTES = {
    gc_content: GC_CONTENTS,
    gender: GENDERS,
    dna_source: DNA_SOURCES,
    sample_sra_hold: SRA_HOLD_VALUES
  }.each_with_object({}) do |(k, v), h|
    h[k] = v.each_with_object({}) { |b, a| a[b.downcase] = b }
  end

  before_validation do |record|
    record.reference_genome_id = 1 if record.reference_genome_id.blank?

    # Unfortunately it appears that some of the functionality of this implementation relies on non-capitalisation!
    # So we remap the lowercased versions to their proper values here
    REMAPPED_ATTRIBUTES.each do |attribute, mapping|
      record[attribute] = mapping.fetch(record[attribute].try(:downcase), record[attribute])
      record[attribute] = nil if record[attribute].blank? # Empty strings should be nil
    end
  end

  validate :reference_genome_found, if: :reference_genome_set_by_name
  # Together these two validations ensure that the first study exists and is valid for the ENA submission.
  validates_each(:ena_study, if: :validating_ena_required_fields?) do |record, _attr, value|
    record.errors.add(:base, 'Sample has no study') if value.blank?
  end


  def strain_or_line
    sample_strain_att
  end

  def sex
    gender && gender.downcase
  end

  def species
    sample_common_name
  end

  def reference_genome_name=(reference_genome_name)
    return unless reference_genome_name.present?
    @reference_genome_set_by_name = reference_genome_name
    self.reference_genome = ReferenceGenome.find_by(name: reference_genome_name)
  end

  def reference_genome_found
    # A reference genome of nil automatically get converted to the reference genome named "", so
    # we need to explicitly check the name has been set as expected.
    return true if reference_genome.name == reference_genome_set_by_name
    errors.add(:base, "Couldn't find a Reference Genome with named '#{reference_genome_set_by_name}'.")
    false
  end

  ### Added from Metaprogramming
  def released?
    sample_sra_hold == 'Public'
  end

  # Rarely actually used
  def release
    self.sample_sra_hold = 'Public'
    save!
  end
  ### End

  def validating_ena_required_fields?
    instance_variable_defined?(:@validating_ena_required_fields) && @validating_ena_required_fields
  end

end

