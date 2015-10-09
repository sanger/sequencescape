#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class ProductCriteria::Basic

  SUPPORTED_WELL_ATTRIBUTES = [:gel_pass, :concentration, :current_volume, :pico_pass, :gender_markers, :gender, :measured_volume, :initial_volume, :molarity]

  attr_reader :passed, :params, :errors, :values
  alias_method :passed?, :passed

  Comparison = Struct.new(:method,:message)

  METHOD_ALIAS = {
    :greater_than => Comparison.new(:>,  '%s too low' ),
    :less_than    => Comparison.new(:<,  '%s too high'),
    :at_least     => Comparison.new(:>=, '%s too low' ),
    :at_most      => Comparison.new(:<=, '%s too high')
  }

  class << self
    # Returns a list of possible criteria to either display or validate
    def available_criteria
      SUPPORTED_WELL_ATTRIBUTES + [:total_micrograms]
    end
  end

  def initialize(params,well)
    @params = params
    @well = well
    @errors = []
    @values = {}
    assess!
  end

  def total_micrograms
    return nil if measured_volume.nil? || concentration.nil?
    (measured_volume * concentration) / 1000.0
  end

  SUPPORTED_WELL_ATTRIBUTES.each do |attribute|
    delegate(attribute, :to => :well_attribute)
  end

  private

  def well_attribute
    @well.well_attribute
  end

  def invalid(attribute,message)
    @passed = false
    @errors << message % attribute.to_s.humanize
  end

  def assess!
    @passed = true
    params.each do |attribute,comparisons|
      value = self.send(attribute)
      values[attribute] = value
      invalid(attribute,'has not been recorded') && next if value.nil? && comparisons.present?
      comparisons.each do |comparison,target|
        value.send(method_for(comparison),target) || invalid(attribute,message_for(comparison))
      end
    end
  end

  def method_for(comparison)
    METHOD_ALIAS[comparison].method || raise(UnknownSpecification, "#{comparison} isn't a recognised means of comparison.")
  end

  def message_for(comparison)
    METHOD_ALIAS[comparison].message || raise(UnknownSpecification, "#{comparison} isn't a recognised means of comparison.")
  end

end
