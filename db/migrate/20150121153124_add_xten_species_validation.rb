class AddXtenSpeciesValidation < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      ev = ExtendedValidator.create!(:behaviour=>'SpeciesValidator',:options=>{:taxon_id=>9606})
      request_types do |request_type|
        request_type.extended_validators << ev
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      ExtendedValidator.find_all_by_behaviour('SpeciesValidator').each do |ev|
        ev.destroy if ev.options == {:taxon_id=>9606}
      end
    end
  end

  def self.request_types
    [
      "hiseq_x_paired_end_sequencing",
      "illumina_a_hiseq_x_paired_end_sequencing",
      "illumina_b_hiseq_x_paired_end_sequencing"
    ].each do |name|
      yield RequestType.find_by_key!(name)
    end
  end
end
