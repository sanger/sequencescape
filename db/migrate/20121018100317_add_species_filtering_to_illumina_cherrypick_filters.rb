class AddSpeciesFilteringToIlluminaCherrypickFilters < ActiveRecord::Migration
  class PlatePurpose < ActiveRecord::Base
    set_table_name('plate_purposes')
    set_inheritance_column(nil)
    serialize :cherrypick_filters
    named_scope :with_name, lambda { |*names| { :conditions => { :name => names } } }
  end

  def self.update
    ActiveRecord::Base.transaction do
      PlatePurpose.with_name(
        IlluminaB::PlatePurposes::STOCK_PLATE_PURPOSE,
        *Pulldown::PlatePurposes::STOCK_PLATE_PURPOSES
      ).find_each do |purpose|
        yield(purpose)
        purpose.save!
      end
    end
  end

  FILTER = 'Cherrypick::Strategy::Filter::BySpecies'

  def self.up
    update do |p|
      p.cherrypick_filters = p.cherrypick_filters.concat([ FILTER ]) unless p.cherrypick_filters.last == FILTER
    end
  end

  def self.down
    update do |p|
      p.cherrypick_filters = p.cherrypick_filters[0..-2] if p.cherrypick_filters.last == FILTER
    end
  end
end
