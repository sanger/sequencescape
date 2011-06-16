# An aliquot can be considered to be an amount of a material in a liquid.  The material could be the DNA
# of a sample, or it might be a library (a combination of the DNA sample and a tag).
class Aliquot < ActiveRecord::Base
  class Receptacle < Asset
    # A receptacle can hold many aliquots.  For example, a multiplexed library tube will contain more than
    # one aliquot.
    has_many :aliquots, :foreign_key => :receptacle_id, :autosave => true
    has_one :primary_aliquot, :class_name => 'Aliquot', :foreign_key => :receptacle_id, :order => 'created_at ASC', :readonly => true

    # Provide some named scopes that will fit with what we've used in the past
    named_scope :with_sample_id, lambda { |id|     { :conditions => { :aliquots => { :sample_id => id        } }, :joins => :aliquots } }
    named_scope :with_sample,    lambda { |sample| { :conditions => { :aliquots => { :sample_id => sample.id } }, :joins => :aliquots } }

    # TODO: Remove these at some point in the future as they're kind of wrong!
    has_one :sample, :through => :primary_aliquot
    deprecate :sample

    def sample=(sample)
      aliquots.clear
      aliquots << Aliquot.new(:sample => sample)
    end
    deprecate :sample=

    def sample_id
      primary_aliquot.try(:sample_id)
    end
    deprecate :sample_id

    def sample_id=(sample_id)
      aliquots.clear
      aliquots << Aliquot.new(:sample_id => sample_id)
    end
    deprecate :sample_id=

    has_one :get_tag, :through => :primary_aliquot, :source => :tag
    deprecate :get_tag

    def tag
      get_tag.try(:map_id) || ''
    end
    deprecate :tag

    def tags
      aliquots
    end
    deprecate :tags
  end

  # Something that is aliquotable can be part of an aliquot.  So sample and tag are both examples.
  module Aliquotable
    def self.included(base)
      base.class_eval do
        extend ClassMethods

        has_many :aliquots
        has_many :receptacles, :through => :aliquots, :uniq => true
        has_one :primary_receptacle, :through => :aliquots, :source => :receptacle, :order => 'assets.created_at'
      end
    end

    module ClassMethods
      def receptacle_alias(name, options = {}, &block)
        has_many(name, options.merge(:through => :aliquots, :source => :receptacle, :uniq => true), &block)
      end
    end
  end

  # An aliquot is held within a receptacle
  belongs_to :receptacle, :class_name => 'Aliquot::Receptacle'
  validates_presence_of :receptacle

  # An aliquot is an amount of a sample
  belongs_to :sample
  validates_presence_of :sample

  # It may have a tag but not necessarily.  If it does, however, that tag needs to be unique within the receptacle.
  belongs_to :tag
  validates_uniqueness_of :tag_id, :scope => :receptacle_id, :allow_nil => true, :allow_blank => true

  # It may have a bait library but not necessarily.
  belongs_to :bait_library
end
