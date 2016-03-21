#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class ProcessAliquotsForSpikedBuffers < ActiveRecord::Migration
  class AssetLink < ActiveRecord::Base
    self.table_name =('asset_links')

    acts_as_dag_links :node_class_name => 'ProcessAliquotsForSpikedBuffers::Asset'
  end

  class Aliquot < ActiveRecord::Base
    self.table_name =('aliquots')

    # NOTE: validations are not here as they are DB constraints and we're not UI based
    belongs_to :receptacle, :class_name => 'ProcessAliquotsForSpikedBuffers::Asset'
    belongs_to :sample
    belongs_to :tag
  end

  class Asset < ActiveRecord::Base
    self.table_name =('assets')

    belongs_to :sample
    has_dag_links :link_class_name => 'ProcessAliquotsForSpikedBuffers::AssetLink'
    has_one :tag_instance, :through => :links_as_child, :source => :ancestor, :conditions => { :sti_type => 'TagInstance' }
    has_many :aliquots, :foreign_key => :receptacle_id, :class_name => 'ProcessAliquotsForSpikedBuffers::Aliquot'

   scope :spiked_buffer, -> { where( :sti_type => 'SpikedBuffer' ) }

    def is_spiked_buffer?
      self.sti_type == 'SpikedBuffer'
    end

    def is_library_tube?
      self.sti_type == 'LibraryTube'
    end

    def process(attributes, indent = 0, &io_method)
      io_method.call("#{'-*-'*indent} Processing #{self.id}(#{self.sti_type}) => #{attributes.inspect} ...")

      begin
        attributes[:sample_id]  = self.sample_id           unless self.sample_id.nil?
        attributes[:tag_id]     = self.tag_instance.tag_id if self.tag_instance.present?
        attributes[:library_id] = self.id                  if self.is_library_tube?
        aliquots.create!(attributes)
      rescue => exception
        io_method.call("WARNING: Looks like duplicate tags for #{self.id}, ignoring for now")
      end

      children.each { |child| child.process(attributes, indent+1, &io_method) }

      io_method.call("#{'-*-'*indent} Done with #{self.id}(#{self.sti_type})")
    end
  end

  def self.up
    ActiveRecord::Base.transaction do
      # Find all of the parents of SpikedBuffer instances that are not themselves SpikedBuffer.
      root_parents, spiked_buffers = [], Asset.spiked_buffer.all
      until spiked_buffers.empty?
        parent_spiked_buffers, non_spiked_buffers = spiked_buffers.shift.parents.partition(&:is_spiked_buffer?)
        root_parents.concat(non_spiked_buffers)
        spiked_buffers.concat(parent_spiked_buffers)
      end

      # Now find all of the parents of the root_parents so that we know we are at the absolute
      # top of the tree
      absolute_roots = []
      until root_parents.empty?
        current_parent = root_parents.shift
        if current_parent.parents.empty?
          absolute_roots.push(current_parent)
        else
          root_parents.concat(current_parent.parents)
        end
      end

      # Walk down the child graph filling in the aliquots from the parent into the child until
      # we reach the end of the graph.  The first thing we're going to do is put in a phiX sample
      # that can then be used all the way down.
      illumina_controls = Study.find_by_name('Illumina controls') or raise StandardError, "Cannot find illumina controls study"
      phiX_sample       = Sample.create!(:name => 'phiX_for_spiked_buffers')
      absolute_roots.shift.process(:sample_id => phiX_sample.id, :study_id => illumina_controls.id, &method(:say)) until absolute_roots.empty?
    end
  end

  def self.down
    # Nothing to do as this isn't sensibly fixed.
  end
end
