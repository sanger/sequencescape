class Api::Messages::FlowcellIO < Api::Base

  module LaneExtensions
    def self.included(base)
      base.class_eval do

        def lane_type
          target_asset.aliquots.all {|a| a.tag.present? } ? 'pool' : 'library'
        end

        def position
          batch_request.position
        end

        def mx_library
          asset.name
        end

        def manual_qc
          event = lab_events.find(
            :first,
            :conditions => {
              :description=>'Quality control'
            },
            :order=>'created_at DESC'
          )
          return event.descriptor_value_for('Passed?') if event.present?
          nil
        end

        def samples
          target_asset.aliquots.reject do |a|
            spiked_in_buffer.present? && spiked_in_buffer.primary_aliquot =~ a
          end
        end

        delegate :spiked_in_buffer, :to=>:target_asset

        def controls
          spiked_in_buffer.present? ? spiked_in_buffer.aliquots : []
        end

      end
    end
  end

  module Extensions
    module ClassMethods
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        named_scope :including_associations_for_json, { :include => [ :uuid_object, :user, :assignee, { :pipeline => :uuid_object }] }

        def flowcell_barcode
          requests.first.lab_events.each {|e| e.descriptor_value_for("Chip Barcode").tap {|bc| return bc unless bc.nil? } }
          nil
        end

        def read_length
          requests.first.request_metadata.read_length
        end
        # We alias is as the json generator assumes each method is called only once.
        alias :reverse_read_length :read_length

        def lanes; requests; end

      end
    end
  end

# NOT YET IMPLIMENTED
#{
#   "flowcell": {
# NOT YET IMPLIMENTED

  renders_model(::Batch)

  map_attribute_to_json_attribute(:flowcell_barcode)
  map_attribute_to_json_attribute(:id,'id_flowcell')
  map_attribute_to_json_attribute(:read_length,'forward_read_length')
  map_attribute_to_json_attribute(:reverse_read_length,'reverse_read_length')

  map_attribute_to_json_attribute(:updated_at)

  with_nested_has_many_association(:lanes) do # actually requests

    map_attribute_to_json_attribute(:manual_qc)
    map_attribute_to_json_attribute(:lane_type)
    map_attribute_to_json_attribute(:position)
    map_attribute_to_json_attribute(:priority)
    map_attribute_to_json_attribute(:mx_library,'provenance_pool_lims')

    with_nested_has_many_association(:samples) do # actually aliquots

      with_association(:tag) do
        map_attribute_to_json_attribute(:map_id, 'tag_index')
        map_attribute_to_json_attribute(:oligo, 'tag_sequence')
        map_attribute_to_json_attribute(:tag_group_id, 'id_tag_set')
        with_association(:tag_group) do
          map_attribute_to_json_attribute(:name, 'name_tag_set')
        end
      end
      map_attribute_to_json_attribute(:library_type, 'id_bait')
      with_association(:bait_library) do
        map_attribute_to_json_attribute(:name, 'id_bait')
      end
      map_attribute_to_json_attribute(:insert_size_to,   'requested_insert_size_from')
      map_attribute_to_json_attribute(:insert_size_from, 'requested_insert_size_to')
      map_attribute_to_json_attribute(:insert_size_to,   'requested_insert_size_from')
      with_association(:sample) do
        map_attribute_to_json_attribute(:uuid, 'sample_uuid')
      end
      with_association(:study) do
        map_attribute_to_json_attribute(:uuid, 'study_uuid')
      end
      with_association(:project) do
        map_attribute_to_json_attribute(:project_cost_code, 'cost_code')
      end
      map_attribute_to_json_attribute(:library_id, 'provenance_lims')
    end
    # ],

    with_nested_has_many_association(:controls) do
      with_association(:tag) do
        map_attribute_to_json_attribute(:map_id, 'tag_index')
        map_attribute_to_json_attribute(:oligo, 'tag_sequence')
        map_attribute_to_json_attribute(:tag_group_id, 'id_tag_set')
        with_association(:tag_group) do
          map_attribute_to_json_attribute(:name, 'name_tag_set')
        end
      end
      with_association(:sample) do
        map_attribute_to_json_attribute(:uuid, 'sample_uuid')
      end
    end
  end


end


