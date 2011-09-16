class Snp::DnaPlate < ActiveRecord::Base
  include Snp
  include ExternalResource

  set_sequence_name "SEQ_DNAPLATE"
  set_primary_key "ID_DNAPLATE"
  set_table_name "dna_plate"

  alias_attribute :id, :id_dnaplate
end if false
