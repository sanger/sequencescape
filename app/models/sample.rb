#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2013,2014,2015 Genome Research Ltd.
require 'rexml/text'
class Sample < ActiveRecord::Base
  include ModelExtensions::Sample
  include Api::SampleIO::Extensions

  cattr_reader :per_page
  @@per_page = 500
  include ExternalProperties
  include Identifiable
  include Uuid::Uuidable
  include StandardNamedScopes
  include Named
  include Aliquot::Aliquotable

  extend EventfulRecord
  has_many_events do
    event_constructor(:created_using_sample_manifest!, Event::SampleManifestEvent, :created_sample!)
    event_constructor(:updated_using_sample_manifest!, Event::SampleManifestEvent, :updated_sample!)
  end

  has_many_lab_events

  ArrayExpressFields = %w(genotype phenotype strain_or_line developmental_stage sex cell_type disease_state compound dose immunoprecipitate growth_condition rnai organism_part species time_point age treatment)
  EgaFields = %w(subject disease treatment gender phenotype)

  acts_as_authorizable



  has_many :study_samples, :dependent => :destroy
  has_many :studies, :through => :study_samples

  has_many :roles, :as => :authorizable
  has_many :comments, :as => :commentable

  receptacle_alias(:assets) do
    def first_of_type(asset_class)
      self.detect { |asset| asset.is_a?(asset_class) }
    end
  end
  receptacle_alias(:wells,        :class_name => 'Well')
  receptacle_alias(:sample_tubes, :class_name => 'SampleTube')

  # Ugh! We need to use finder sql here as our relationships are complicated
  # Note: The interpolation of the id is something done in rails 2.3, but is deprecated
  # in >3. You'll need to use a proc in that context.
  has_many :asset_groups, :finder_sql => 'SELECT DISTINCT asset_groups.* FROM samples
  INNER JOIN aliquots ON aliquots.sample_id = samples.id
  INNER JOIN asset_group_assets ON aliquots.receptacle_id = asset_group_assets.asset_id
  INNER JOIN asset_groups ON asset_group_assets.asset_group_id = asset_groups.id
  WHERE samples.id = #{id} AND asset_groups.id IS NOT NULL;'
  has_many :submissions, :finder_sql => 'SELECT DISTINCT submissions.* FROM samples
  INNER JOIN aliquots ON aliquots.sample_id = samples.id
  INNER JOIN requests ON aliquots.receptacle_id = requests.asset_id
  INNER JOIN submissions ON requests.submission_id = submissions.id
  WHERE samples.id = #{id} AND submissions.id IS NOT NULL;'

  belongs_to :sample_manifest

  validates_presence_of :name
  validates_format_of :name, :with => /^[\w_-]+$/i, :message => I18n.t('samples.name_format'), :if => :new_name_format, :on => :create
  validates_format_of :name, :with => /^[\(\)\+\s\w._-]+$/i, :message => I18n.t('samples.name_format'), :if => :new_name_format, :on => :update
  validates_uniqueness_of :name, :on => :create, :message => "already in use", :unless => :sample_manifest_id?
  validates_each(:name, :on => :save, :unless => :can_rename_sample?) do |record,attr,value|
    record.errors.add(:name, 'cannot be changed') if record.name_changed? and not record.new_record?
  end

  extend ValidationStateGuard
  validation_guard(:can_rename_sample)

  def rename_to!(new_name)
    update_attributes!(:name => new_name)
  end
  validation_guarded_by(:rename_to!, :can_rename_sample)

  before_destroy :safe_to_destroy

  def safe_to_destroy
    return true unless receptacles.present? || has_submission?
    errors.add_to_base("Remove '#{name}' from assets before destroying") if receptacles.present?
    errors.add_to_base("You can't delete '#{name}' because is linked to a submission.") if has_submission?
    return false
  end
  private :safe_to_destroy

  named_scope :with_name, lambda { |*names| { :conditions => { :name => names.flatten } } }

  named_scope :for_search_query, lambda { |query,with_includes|
    { :conditions => [ 'name LIKE ? OR id=?', "%#{query}%", query ] }
  }

  named_scope :non_genotyped, :conditions => "samples.id not in (select propertied_id from external_properties where propertied_type = 'Sample' and `key` = 'genotyping_done'  )"

  def self.by_name(sample_id)
    self.find_by_name(sample_id)
  end

  def select_study(sample_id)
    sample = self.find(sample_id)
    sample.studies
  end

  def shorten_sanger_sample_id
    short_sanger_id = case sanger_sample_id
      when blank? then name
      when sanger_sample_id.size <10 then sanger_sample_id
      when /([\d]{7})$/ then $1
      else
        sanger_sample_id
    end

    short_sanger_id
  end

  def has_request
    requests.present?
  end

  def has_request_all_cancelled?
    self.requests.all?(&:cancelled?)
  end

  def has_submission?
    has_submission = false
    if self.has_request
      if has_request_all_cancelled?
        sra_hold_value = self.sample_metadata.sample_sra_hold
        if sra_hold_value.nil?
          has_submission = false
        elsif 'hold' != sra_hold_value
          has_submission = true
        else
          has_submission = false
        end
      else
        has_submission = true
      end
    else # We have no requests, we're probably S2 (Or very old Sequencescape)
         # This is a hack, but I'll get this tidied up.
      has_submission = true
    end
    return has_submission
  end

  def has_ebi_accession_number
    has_ebi_accession_number = false

    self.studies.each do |study|
      if ! study.ebi_accession_number.blank?
        has_ebi_accession_number = true
      end
    end

    return has_ebi_accession_number
  end

  # TODO: remove as this is no longer needed (validation of name change will fail)
  # On update, checks if updating the name is possible
  def name_change?(new_name)
    self.name == new_name ? false : true
  end

  # TODO: move to sample_metadata and delegate
  def released?
    self.sample_metadata.sample_sra_hold == 'Public'
  end

  def release
    self.sample_metadata.sample_sra_hold = 'Public'
    self.sample_metadata.save!
  end

  def ebi_accession_number
    self.sample_metadata.sample_ebi_accession_number
  end

  def accession_number?
    not self.ebi_accession_number.blank?
  end

  # If there is no existing ebi_accession_number and we have a taxon id
  # and we have a common name for the sample return true else false
  def accession_could_be_generated?
    return false unless self.sample_metadata.sample_ebi_accession_number.blank?
    required_tags.each do |tag|
      return false if self.sample_metadata.send(tag).blank?
    end
    # We have everything needed to generate an accession so...
    true
  end

  def self.submissions_by_assets(study_id, asset_group_id)
    return [] if asset_group_id == '0'

    study = Study.find(study_id)
    asset_group_assets = AssetGroupAsset.find(:all, :conditions => [" asset_group_id = ? ", asset_group_id])
    return study.submissions.that_submitted_asset_id(asset_group_assets.first.asset_id).all
  end

  def error
    "Default error message"
  end

  def sample_external_name
    self.name
  end

  def sample_empty?(supplier_sample_name = self.name)
    return true if self.empty_supplier_sample_name
    sample_supplier_name_empty?(supplier_sample_name)
  end

  def sample_supplier_name_empty?(supplier_sample_name)
    supplier_sample_name.blank? || [ 'empty', 'blank', 'water', 'no supplier name available', 'none' ].include?(supplier_sample_name.downcase)
  end

  def accession_service
    return nil if self.studies.empty?
    self.studies.first.accession_service
  end

  # at the moment return a string which is a comma separated list of snp plate id
  def genotyping_done
    self.get_external_value('genotyping_done')
  end

  def genotyping_snp_plate_id
    s = genotyping_done
    if s && s =~ /:/
      s.split(":").second.to_i # take the firt integer
    else # old value
      ""
    end
  end

  GC_CONTENTS     = [ 'Neutral', 'High AT', 'High GC' ]
  GENDERS         = [ 'Male', 'Female', 'Mixed', 'Hermaphrodite', 'Unknown', 'Not Applicable' ]
  DNA_SOURCES     = [ 'Genomic', 'Whole Genome Amplified', 'Blood', 'Cell Line','Saliva','Brain','FFPE',
                      'Amniocentesis Uncultured', 'Amniocentesis Cultured', 'CVS Uncultured', 'CVS Cultured', 'Fetal Blood' ]
  SRA_HOLD_VALUES = [ 'Hold', 'Public', 'Protect' ]
  AGE_REGEXP      = '\d+(?:\.\d+|\-\d+|\.\d+\-\d+\.\d+|\.\d+\-\d+\.\d+)?\s+(?:second|minute|day|week|month|year)s?|Not Applicable|N/A|To be provided'
  DOSE_REGEXP     = '\d+(?:\.\d+)?\s+\w+(?:\/\w+)?|Not Applicable|N/A|To be provided'

  extend Metadata
  has_metadata do
    include ReferenceGenome::Associations
    association(:reference_genome, :name, :required => true)

    attribute(:organism)
    attribute(:cohort)
    attribute(:country_of_origin)
    attribute(:geographical_region)
    attribute(:ethnicity)
    attribute(:volume)
    attribute(:supplier_plate_id)
    attribute(:mother)
    attribute(:father)
    attribute(:replicate)
    attribute(:gc_content, :in => Sample::GC_CONTENTS)
    attribute(:gender, :in => Sample::GENDERS)
    attribute(:donor_id)
    attribute(:dna_source, :in => Sample::DNA_SOURCES)
    attribute(:sample_public_name)
    attribute(:sample_common_name)
    attribute(:sample_strain_att)
    attribute(:sample_taxon_id)
    attribute(:sample_ebi_accession_number)
    attribute(:sample_description)
    attribute(:sample_sra_hold, :in => Sample::SRA_HOLD_VALUES)

    attribute(:sibling)
    attribute(:is_resubmitted)              # TODO[xxx]: selection of yes/no?
    attribute(:date_of_sample_collection)   # TODO[xxx]: Date field?
    attribute(:date_of_sample_extraction)   # TODO[xxx]: Date field?
    attribute(:sample_extraction_method)
    attribute(:sample_purified)             # TODO[xxx]: selection of yes/no?
    attribute(:purification_method)         # TODO[xxx]: tied to the field above?
    attribute(:concentration)
    attribute(:concentration_determined_by)
    attribute(:sample_type)
    attribute(:sample_storage_conditions)

    # Array Express
    attribute(:genotype)
    attribute(:phenotype)
    #attribute(:strain_or_line) strain
    #TODO: split age in two fields and use a composed_of
    attribute(:age, :with => Regexp.new("^#{Sample::AGE_REGEXP}$"))
    attribute(:developmental_stage)
    #attribute(:sex) gender
    attribute(:cell_type)
    attribute(:disease_state)
    attribute(:compound) #TODO : yes/no?
    attribute(:dose, :with => Regexp.new("^#{Sample::DOSE_REGEXP}$"))
    attribute(:immunoprecipitate)
    attribute(:growth_condition)
    attribute(:rnai)
    attribute(:organism_part)
    #attribute(:species) common name
    attribute(:time_point)

    #EGA
    attribute(:treatment)
    attribute(:subject)
    attribute(:disease)


    with_options(:if => :validating_ena_required_fields?) do |ena_required_fields|
      # ena_required_fields.validates_presence_of :sample_common_name
      # ena_required_fields.validates_presence_of :sample_taxon_id
      ena_required_fields.validates_presence_of :service_specific_fields
    end

    # The spreadsheets that people upload contain various fields that could be mistyped.  Here we ensure that the
    # capitalisation of these is correct.
    REMAPPED_ATTRIBUTES = {
      :gc_content              => GC_CONTENTS,
      :gender                  => GENDERS,
      :dna_source              => DNA_SOURCES,
      :sample_sra_hold         => SRA_HOLD_VALUES
#      :reference_genome        => ??
    }.inject({}) do |h,(k,v)|
      h[k] = v.inject({}) { |a,b| a[b.downcase] = b ; a }
      h
    end

    before_validation do |record|
      record.reference_genome_id = 1 if record.reference_genome_id.blank?

      # Unfortunately it appears that some of the functionality of this implementation relies on non-capitalisation!
      # So we remap the lowercased versions to their proper values here
      REMAPPED_ATTRIBUTES.each do |attribute,mapping|
        record[attribute] = mapping.fetch(record[attribute].try(:downcase), record[attribute])
        record[attribute] = nil if record[attribute].blank? # Empty strings should be nil
      end
    end
  end

    include_tag(:sample_strain_att)
    include_tag(:sample_description)

    include_tag(:gender, :services=>:EGA)
    include_tag(:phenotype, :services=>:EGA)
    include_tag(:donor_id, :services=>:EGA)

    require_tag(:sample_taxon_id)
    require_tag(:sample_common_name)
    require_tag(:gender, :EGA)
    require_tag(:phenotype, :EGA)
    require_tag(:donor_id, :EGA)

  # This needs to appear after the metadata has been defined to ensure that the Metadata class
  # is present.
  include SampleManifest::InputBehaviour::SampleUpdating

  class Metadata

    attr_reader :reference_genome_set_by_name
    # here we are aliasing ArrayExpress attribute from normal one
    # This is easier that way so the name is exactly the name of the array-express field
    # and the values can be easily remapped
    # The other solution would be to have a different label for the accession file and the xml/edit page
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
      self.reference_genome = ReferenceGenome.find_by_name(reference_genome_name)
    end

    # If we set a reference genome via its name, we want to validate that we found it.
    # We can't just raise and exception when we don't find it, as this cases the sample manifest
    # delayed job to fail completely.
    validate :reference_genome_found, :if => :reference_genome_set_by_name

    def reference_genome_found
      # A reference genome of nil automatically get converted to the reference genome named "", so
      # we need to explicitly check the name has been set as expected.
      return true if reference_genome.name == reference_genome_set_by_name
      errors.add(:base,"Couldn't find a Reference Genome with named '#{reference_genome_set_by_name}'.")
      false
    end

  end


  # Together these two validations ensure that the first study exists and is valid for the ENA submission.
  validates_each(:ena_study, :if => :validating_ena_required_fields?) do |record, attr, value|
    record.errors.add_to_base('Sample has no study') if value.blank?
  end
  validates_associated(:ena_study, :allow_blank => true, :if => :validating_ena_required_fields?)

  def ena_study
    @ena_study
  end

  def validating_ena_required_fields_with_first_study=(state)
    self.validating_ena_required_fields_without_first_study = state
    @ena_study.try(:validating_ena_required_fields=, state)
  end
  alias_method_chain(:validating_ena_required_fields=, :first_study)

  def validate_ena_required_fields!
    # Do not alter the order of this line, otherwise @ena_study won't be set correctly!
    @ena_study, self.validating_ena_required_fields = self.studies.first, true
    self.valid? or raise ActiveRecord::RecordInvalid, self
  rescue ActiveRecord::RecordInvalid => exception
    @ena_study.errors.full_messages.each do |message|
      self.errors.add_to_base("#{ message } on study")
    end unless @ena_study.nil?
    raise
  ensure
    # Do not alter the order of this line, otherwise the @ena_study won't be reset!
    self.validating_ena_required_fields, @ena_study = false, nil
  end

  def sample_reference_genome
    reference_genome = self.sample_metadata.reference_genome
    reference_genome = self.primary_study.try(:study_metadata).try(:reference_genome) if ( reference_genome.nil? ) || reference_genome.name.blank?
    reference_genome
  end

  def affiliated_with?(object)
    case
    when object.respond_to?(:sample_id)
      self.id == object.sample_id
    when object.respond_to?(:sample_ids)
      object.sample_ids.include?(self.id)
    else
      nil
    end
  end

  def withdraw_consent
    self.update_attribute(:consent_withdrawn, true)
  end

  # These don't really belong here, but exist due to the close coupling between sample
  # and its initial aliquot in the sample manifest.
  delegate :specialized_from_manifest=, :to => :primary_receptacle
  delegate :library_information=, :to => :primary_receptacle

end
