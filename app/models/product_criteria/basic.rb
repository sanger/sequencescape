#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class ProductCriteria::Basic

  attr_reader :passed, :params, :errors
  alias_method :passed?, :passed

  Comparator = Struct.new(:method,:message)

  METHOD_ALIAS = {
    :greater_than => Comparator.new(:>,  'too low' ),
    :less_than    => Comparator.new(:<,  'too high'),
    :at_least     => Comparator.new(:>=, 'too low' ),
    :at_most      => Comparator.new(:<=, 'too high')
  }

  def initialize(params,well)
    @params = params
    @well = well
    @errors = []
    validate!
  end

  def total_micrograms
    (measured_volume * concentration) / 1000.0
  end

  delegate :measured_volume, :concentration, :to => :well_attribute


  private

  def well_attribute
    @well.well_attribute
  end

  def invalid(attribute,comparison)
    @passed = false
    @errors << "#{attribute.to_s.humanize} #{message_for(comparison)}"
  end

  def validate!
    @passed = true
    params.each do |attribute,comparisons|
      value = self.send(attribute)
      comparisons.each do |comparison,target|
        value.send(method_for(comparison),target) || invalid(attribute,comparison)
      end
    end
  end

  def method_for(comparator)
    METHOD_ALIAS[comparator].method || raise(UnknownSpecification, "#{comparator} isn't a recognised means of comparison.")
  end

  def message_for(comparator)
    METHOD_ALIAS[comparator].message || raise(UnknownSpecification, "#{comparator} isn't a recognised means of comparison.")
  end

end
