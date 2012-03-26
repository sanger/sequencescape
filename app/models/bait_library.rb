class BaitLibrary < ActiveRecord::Base
  module Associations
    def self.included(base)
      base.class_eval do
        belongs_to :bait_library
      end
    end
  end

  class Supplier < ActiveRecord::Base
    set_table_name('bait_library_suppliers')

    # The names of suppliers needs to be unique
    validates_presence_of :name
    validates_uniqueness_of :name

    # They supply many bait libraries
    has_many :bait_libraries, :foreign_key => :bait_library_supplier_id
  end

  # All bait libraries belong to a supplier
  belongs_to :bait_library_supplier, :class_name => 'BaitLibrary::Supplier'
  validates_presence_of :bait_library_supplier

  # Within a supplier we have a unique identifier for each bait library.  Custom bait libraries
  # do not have this identifier, so nil is permitted.
  validates_uniqueness_of :supplier_identifier, :scope => :bait_library_supplier_id, :allow_nil => true

  # The names of the bait library are considered unique within the supplier
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :bait_library_supplier_id

  # All bait libraries target a specific species and cannot be mixed
  validates_presence_of :target_species

  # All bait libraries have a bait library type
  belongs_to :bait_library_type

end
