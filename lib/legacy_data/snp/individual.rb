class Snp::Individual < ActiveRecord::Base
  include Snp
  include ExternalResource

  set_sequence_name "SEQ_IND"
  set_primary_key "ID_IND"
  set_table_name "INDIVIDUAL"

  alias_attribute :id, :id_ind
  has_many :individual_name, :foreign_key => "ID_IND", :class_name => "Snp::IndividualName"

  def set_value(sample)
    set_identifiable(sample)
    self.id_ind      = Snp::Individual.next_value
    self.clonename   = sample.name
    self.is_control  = false
    gender           = sample.sample_metadata.gender
    self.gender      = gender ? gender.value == 'male' ? 1 : 2 : 0
    self.condition   = 0
    organism         = sample.sample_metadata.organism

    value = organism && organism.value
    if value.nil? or value.blank?
      self.speciesname = 'Human'
    else
      self.speciesname = value
    end
    self.ethnicity   = 0
  end
  
  def gender_string
    case self.gender
    when 0 then ""
    when 1 then "male"
    when 2 then "female"
    else "Unrecognised value"
    end
  end

end
