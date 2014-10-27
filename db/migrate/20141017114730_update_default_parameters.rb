class UpdateDefaultParameters < ActiveRecord::Migration

  Validator = Struct.new(:option,:values,:default,:destroy_on_revert)

  def self.up
    ActiveRecord::Base.transaction do
      each_request_type_and_validators do |rt_key,validators|
        rt = RequestType.find_by_key!(rt_key)
        validators.each do |v|
          rt.request_type_validators.find_or_create_by_request_option(v.option).tap do |validator|
            validator.valid_options = RequestType::Validator::ArrayWithDefault.new(v.values||validator.valid_options,v.default)
          end.save!
        end
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      each_request_type_and_validators do |rt_key,validators|
        rt = RequestType.find_by_key!(rt_key)
        validators.each do |v|
          rt.request_type_validators.find_by_request_option(v.option).destroy if v.destroy_on_revert
        end
      end
    end
  end

  def self.each_request_type_and_validators
    [
      {:rt=>'pacbio_sequencing',:validators=>[
        Validator.new('insert_size',[500,1000,2000,5000,10000,20000],500,true),
        Validator.new('sequencing_type',['Standard','MagBead'],'Standard',true)
      ]}
    ].each do |hash|
      yield(hash[:rt],hash[:validators])
    end
  end
end
