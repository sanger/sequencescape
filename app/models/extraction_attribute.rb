
class ExtractionAttribute < ActiveRecord::Base
  include Uuid::Uuidable

  validates_presence_of :created_by

  # This is the target asset for which to update the state
  belongs_to :target, class_name: 'Asset', foreign_key: :target_id
  validates_presence_of :target

  validates_presence_of :attributes_update

  serialize :attributes_update

  before_save :update_performed

  VALID_WELL_ATTRIBUTES = ['measured_volume']

  def update_performed
    attributes_update['wells'].each do |w|
      next unless w['sanger_sample_name'] || w['sanger_sample_id']
      sample = Sample.find_by(name: w['sanger_sample_name']) || Sample.find_by(sanger_sample_id: w['sanger_sample_id'])
      well = target.wells.located_at(w['location']).first
      if well.aliquots.select { |a| a.sample == sample }.empty?
        well.aliquots.create!(sample: sample)
      end
      w_attrs = w.keep_if { |k, _v| VALID_WELL_ATTRIBUTES.include?(k) }
      unless w_attrs.blank?
        well.well_attribute.update_attributes!(w_attrs)
      end
    end
    self.attributes_update = nil
  end
  private :update_performed
end
