class MoveSampleToAliquots < ActiveRecord::Migration
  class AssetLink < ActiveRecord::Base
    set_table_name('asset_links')

    acts_as_dag_links :node_class_name => 'MoveSampleToAliquots::Asset'
  end

  class Aliquot < ActiveRecord::Base
    set_table_name('aliquots')

    belongs_to :receptacle, :class_name => 'MoveSampleToAliquots::Asset'
    validates_presence_of :receptacle
    belongs_to :sample
    validates_presence_of :sample
    belongs_to :tag

    # Validate that the tag is unique within the context of the receptacle.  Multiple aliquots
    # require unique tags.
    validates_uniqueness_of :tag_id, :scope => :receptacle_id
  end

  class Request < ActiveRecord::Base
    set_table_name('requests')

    # More sensible names for the assets
    belongs_to :source_asset, :class_name => 'MoveSampleToAliquots::Asset', :foreign_key => :asset_id
    belongs_to :target_asset, :class_name => 'MoveSampleToAliquots::Asset', :foreign_key => :target_asset_id
  end

  class Asset < ActiveRecord::Base
    set_table_name('assets')

    # Sometimes we have to skip from the asset to the next asset via a request.  This should return the cases
    # where that should happen.
    has_many :requests_to_skip_to, :class_name => 'MoveSampleToAliquots::Request', :foreign_key => :asset_id, :conditions => { :sti_type => 'PulldownMultiplexedLibraryCreationRequest' }

    # We're removing these ...
    belongs_to :sample
    has_dag_links :link_class_name => 'MoveSampleToAliquots::AssetLink'
    has_one :tag_instance, :through => :links_as_child, :source => :ancestor, :conditions => { :sti_type => 'TagInstance' }

    # ... and replacing them with these
    has_many :aliquots, :foreign_key => :receptacle_id, :class_name => 'MoveSampleToAliquots::Aliquot' do
      # Returns a list of Aliquot instances that can be attached to another asset.  It also ensures that
      # the aliquots on the asset are maintained correctly.
      def for_attachment
        parent_aliquots = self.map(&:clone)
        if parent_aliquots.empty?
          return [] if proxy_owner.sample_id.nil?   # This is an empty receptacle so no point going any further

          aliquot         = Aliquot.new(:sample_id => proxy_owner.sample_id)
          aliquot.tag_id  = proxy_owner.tag_instance.tag_id if proxy_owner.tag_instance.present?
          parent_aliquots = [ aliquot ]

          self << aliquot.clone    # This is our own aliquot too
        elsif parent_aliquots.size == 1 and proxy_owner.tag_instance.present?
          if parent_aliquots.first.tag_id.present? and parent_aliquots.first.tag_id != proxy_owner.tag_instance.tag_id
            raise StandardError, "Asset #{proxy_owner.id} has mismatching tags" 
          end

          # Update the tag on our aliquot
          parent_aliquots.first.tag_id = proxy_owner.tag_instance.tag_id
          self.first.update_attributes!(:tag_id => proxy_owner.tag_instance.tag_id)
        end

        parent_aliquots
      end

      # Attach any of the aliquots that are missing from the specified list.
      def attach_missing_from(aliquots)
        return if aliquots.empty?

        missing_aliquots = aliquots.map(&:clone)
        self.each do |aliquot|
          missing_aliquots.delete_if do |parent_aliquot|
            (parent_aliquot.sample == aliquot.sample) and (parent_aliquot.tag == aliquot.tag)
          end
        end
        self << missing_aliquots unless missing_aliquots.empty?
      end
    end

    ROOT_LEVEL_ASSET_CONDITIONS = {
      :conditions => [
        'id IN (SELECT DISTINCT ancestor_id FROM asset_links WHERE ancestor_id NOT IN (SELECT DISTINCT descendant_id FROM asset_links)) AND sti_type!=?',
        'TagInstance'
      ]
    }

    def self.at_root(options = {}, &block)
      # Can't use a named_scope here because that seems to cause find_each to behave oddly, where
      # every call to 'asset.children' then includes the scope which has NULL conditions.
      total = count(ROOT_LEVEL_ASSET_CONDITIONS)
      find_in_batches(options.merge(ROOT_LEVEL_ASSET_CONDITIONS)) do |batch|
        batch.each_with_index do |asset, index|
          yield(asset, index, total)
        end
      end
    end
  end

  EAGER_LOADING_FOR_ASSETS   = { :include => [ :aliquots, :tag_instance ] }
  EAGER_LOADING_FOR_REQUESTS = { :include => { :source_asset => [ :aliquots, :tag_instance ], :target_asset => [ :aliquots, :tag_instance ] } }

  # These are all of the classes that are considered to be receptacles.  Any others can be ignored
  # when it comes to aliquot processing.
  RECEPTACLES = [
    # The common ones ...
    'SampleTube',               # Should only have a sample
    'LibraryTube',              # Should have both a sample and a tag
    'MultiplexedLibraryTube',   # Actually has nothing but ends up with multiple aliquots
    'Well',                     # Nothing, or a sample, but ends up with one or more aliquots
    'Lane',                     # Actually has nothing but ends up with one or more aliquots

    # The oddities ... which really shouldn't exist ...
    'PacBioLibraryTube',
    'StockLibraryTube',
    'StockMultiplexedLibraryTube',
    'PulldownMultiplexedLibraryTube'
  ]

  def self.walk_from_asset(parent, depth = 0)
    return if parent.nil?   # Guard because we can't guarantee it's not, unfortunately
    raise StandardError, "Asset #{parent.id} has exceeded the maximum expected depth (do we have a cycle?)" if depth > 10

    # Cunning way to handle the depth our children are at!
    walk_next_depth = lambda { |asset| walk_from_asset(asset, depth+1) }

    say("#{'-*-'*depth}Walking asset #{parent.id} (#{parent.sti_type})")

    # If the parent is of a type that should not have aliquots then we do not process it, except
    # to process any children it might have.  This covers, in particular, plates, where the wells
    # are children.
    children = parent.children.all(EAGER_LOADING_FOR_ASSETS)
    return children.each(&walk_next_depth) unless RECEPTACLES.include?(parent.sti_type)

    parent_aliquots = parent.aliquots.for_attachment
    children.each { |child| child.aliquots.attach_missing_from(parent_aliquots) }
    children.each(&walk_next_depth)

    # If the well has a "Cherrypick for Pulldown" request leading from it then we should jump
    # across to the target asset of that request.
    request_assets = parent.requests_to_skip_to.map(&:target_asset).compact.uniq
    request_assets.each { |asset| asset.aliquots.attach_missing_from(parent_aliquots) }
    request_assets.each(&walk_next_depth)
  end

  def self.up
    # In the majority of cases we can walk the asset graph in order to ensure that the aliquots
    # are properly transferred from parents to children.  We can start at the root of the graph,
    # where those assets have no parents, and walk along the child relationships.
    #
    # However, there is a small snag to this as, with pulldown multiplexing there is a break in
    # this asset graph that means we have to make a single hop into the request graph.  It's not
    # when you reach a well with no children: it's actually the parent well of those that has the
    # request that needs to be followed.
    #
    # Because the intention is to run this separately to the release migrations, and on a separate
    # database, there is no point in being transactional here.  If things go wrong then the
    # aliquots table can be dropped/truncated and the migration fixed and re-run.  It will also
    # mean that the MySQL server isn't storing up the transactional data and so should be 
    # quicker.
    migration_started = Time.now
    Asset.at_root(EAGER_LOADING_FOR_ASSETS) do |asset, index, count|
      say("Processing #{index+1}/#{count} ...")

      start = Time.now
      walk_from_asset(asset)
      finish = Time.now

      say("Finished #{index+1}/#{count} (%0.03fs, %ds since start)" % [ finish-start, finish-migration_started ])
    end
  rescue => exception
    # Here's our transaction!
    Aliqout.delete_all
    raise
  end

  def self.down
    # We cannot reverse this migration as it is not possible to (sensibly) work out where the tags
    # and samples came from.  More importantly, once assets start having multiple aliquots it is
    # incredibly hard (and a waste of time) to unwind these.
    raise ActiveRecord::IrreversibleMigration, "There is no way to return from the aliquot model"
  end
end
