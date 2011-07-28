# An aliquot can be considered to be an amount of a material in a liquid.  The material could be the DNA
# of a sample, or it might be a library (a combination of the DNA sample and a tag).
class Aliquot < ActiveRecord::Base
  include Uuid::Uuidable
  class Receptacle < Asset
    include Transfer::State

    has_many :transfer_requests, :class_name => 'TransferRequest', :foreign_key => :target_asset_id
    has_many :transfer_requests_as_source, :class_name => 'TransferRequest', :foreign_key => :asset_id
    has_many :transfer_requests_as_target, :class_name => 'TransferRequest', :foreign_key => :target_asset_id

    def default_state
      nil
    end

    # A receptacle can hold many aliquots.  For example, a multiplexed library tube will contain more than
    # one aliquot.
    has_many :aliquots, :foreign_key => :receptacle_id, :autosave => true
    has_one :primary_aliquot, :class_name => 'Aliquot', :foreign_key => :receptacle_id, :order => 'created_at ASC', :readonly => true

    # Named scopes for the future
    named_scope :include_aliquots, :include => { :aliquots => [ :sample, :tag, :bait_library ] }

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

    def primary_aliquot_if_unique
      aliquots.first if aliquots.size == 1
    end

    def type
      self.class.name.underscore
    end
  end

  # Something that is aliquotable can be part of an aliquot.  So sample and tag are both examples.
  module Aliquotable
    def self.included(base)
      base.class_eval do
        extend ClassMethods

        has_many :aliquots
        has_many :receptacles, :through => :aliquots, :uniq => true
        has_one :primary_receptacle, :through => :aliquots, :source => :receptacle, :order => 'assets.created_at'

        # Unfortunately we cannot use has_many :through because it ends up being a through through a through.  Really we want:
        #   has_many :requests, :through => :assets
        #   has_many :submissions, :through => :requests
        # But 'assets' is already a through!
        has_many :requests, :finder_sql => %q{
          SELECT DISTINCT requests.*
          FROM requests
          JOIN aliquots ON aliquots.receptacle_id=requests.asset_id
          WHERE aliquots.sample_id=#{id}
        }
        has_many :submissions, :finder_sql => %q{
          SELECT DISTINCT submissions.*
          FROM submissions
          JOIN requests ON requests.submission_id=submissions.id
          JOIN aliquots ON aliquots.receptacle_id=requests.asset_id
          WHERE aliquots.sample_id=#{id}
        }
      end
    end

    module ClassMethods
      def receptacle_alias(name, options = {}, &block)
        has_many(name, options.merge(:through => :aliquots, :source => :receptacle, :uniq => true), &block)
      end
    end
  end

  include Api::AliquotIO::Extensions
  # An aliquot is held within a receptacle
  belongs_to :receptacle, :class_name => 'Asset'
  validates_presence_of :receptacle

  # An aliquot can belong to a study and a project.
  belongs_to :study
  belongs_to :project

  # An aliquot is an amount of a sample
  belongs_to :sample
  validates_presence_of :sample

  # It may have a tag but not necessarily.  If it does, however, that tag needs to be unique within the receptacle.
  belongs_to :tag
  validates_uniqueness_of :tag_id, :scope => :receptacle_id, :allow_nil => true, :allow_blank => true

  # It may have a bait library but not necessarily.
  belongs_to :bait_library

  # An aliquot can represent a library, which is a processed sample that has been fragmented.  In which case it 
  # has a receptacle that held the library aliquot and has an insert size describing the fragment positions.
  class InsertSize < Range
    alias_method :from, :first
    alias_method :to,   :last
  end

  # It can belong to a library asset
  belongs_to :library, :class_name => 'Aliquot::Receptacle'
  composed_of :insert_size, :mapping => [%w{insert_size_from from}, %w{insert_size_to to}], :class_name => 'Aliquot::InsertSize', :allow_nil => true
end
