#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class ProductCriteria::Basic

  attr_reader :passed, :params, :errors
  alias_method :passed?, :passed

  Comparison = Struct.new(:method,:message)

  METHOD_ALIAS = {
    :greater_than => Comparison.new(:>,  'too low' ),
    :less_than    => Comparison.new(:<,  'too high'),
    :at_least     => Comparison.new(:>=, 'too low' ),
    :at_most      => Comparison.new(:<=, 'too high')
  }

  def initialize(params,well)
    @params = params
    @well = well
    @errors = []
    assess!
  end

  def total_micrograms
    return nil if measured_volume.nil? || concentration.nil?
    (measured_volume * concentration) / 1000.0
  end

  delegate :measured_volume, :concentration, :to => :well_attribute


  private

  def well_attribute
    @well.well_attribute
  end

  def invalid(attribute,message)
    puts "Failing #{attribute}: #{message}"
    @passed = false
    @errors << message
  end

  def assess!
    @passed = true
    params.each do |attribute,comparisons|
      value = self.send(attribute)
      invalid(attribute,'has not been recorded') && next if value.nil?
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
