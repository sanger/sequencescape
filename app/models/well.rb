class Well < Asset
  include Cherrypick::VolumeByNanoGrams
  include Cherrypick::VolumeByNanoGramsPerMicroLitre
  include Cherrypick::VolumeByMicroLitre
  include StudyReport::WellDetails

  contained_by :plate
  delegate :location, :to => :container , :allow_nil => true
  @@per_page = 500
  has_one :well_attribute

  # # TODO:  remove asset link and use tag_instance via content
  #contains :tag_instance
  has_one :tag_instance, :through => :links_as_parent, :source => :descendant, :conditions => { :sti_type => 'TagInstance' }
  after_create :create_well_attribute_if_not_exists
  
  named_scope :including_associations_for_json, { :include => [:uuid_object, :map, :well_attribute, :container, { :sample => :uuid_object } ] }

  named_scope :with_blank_samples, { :conditions => { :samples => { :empty_supplier_sample_name => true } }, :joins => :sample }

  class << self
    def delegate_to_well_attribute(attribute, options = {})
      class_eval <<-END_OF_METHOD_DEFINITION
        def get_#{attribute}
          self.well_attribute.#{attribute} || #{options[:default].inspect}
        end
      END_OF_METHOD_DEFINITION
    end

    def writer_for_well_attribute_as_float(attribute)
      class_eval <<-END_OF_METHOD_DEFINITION
        def set_#{attribute}(value)
          self.well_attribute.update_attributes!(:#{attribute} => value.to_f)
        end
      END_OF_METHOD_DEFINITION
    end
  end

  #hotfix
  def well_attribute_with_creation
    self.well_attribute_without_creation || self.build_well_attribute
  end
  alias_method_chain(:well_attribute, :creation)

  delegate_to_well_attribute(:pico_pass)
  delegate_to_well_attribute(:sequenom_count)
  delegate_to_well_attribute(:gel_pass)
  delegate_to_well_attribute(:study_id)
  delegate_to_well_attribute(:gender)

  delegate_to_well_attribute(:concentration)
  alias_method(:get_pico_result, :get_concentration)
  writer_for_well_attribute_as_float(:concentration)

  delegate_to_well_attribute(:current_volume)
  alias_method(:get_volume, :get_current_volume)
  writer_for_well_attribute_as_float(:current_volume)

  delegate_to_well_attribute(:buffer_volume, :default => 0.0)
  writer_for_well_attribute_as_float(:buffer_volume)

  delegate_to_well_attribute(:requested_volume)
  writer_for_well_attribute_as_float(:requested_volume)

  delegate_to_well_attribute(:picked_volume)
  writer_for_well_attribute_as_float(:picked_volume)

  delegate_to_well_attribute(:gender_markers)
  
  def update_gender_markers!(gender_markers, resource)
    if self.well_attribute.gender_markers == gender_markers
      gender_marker_event = self.events.find_by_family('update_gender_markers', :order => 'id desc')
      if gender_marker_event.blank?
        self.events.update_gender_markers!(resource)
      elsif resource == 'SNP'  && gender_marker_event.content != resource
        self.events.update_gender_markers!(resource)
      end
    else
      self.events.update_gender_markers!(resource)
    end
    
    self.well_attribute.update_attributes!(:gender_markers => gender_markers)
  end
  
  def update_sequenom_count!(sequenom_count, resource)
    unless self.well_attribute.sequenom_count == sequenom_count
      self.events.update_sequenom_count!(resource)
    end
    self.well_attribute.update_attributes!(:sequenom_count => sequenom_count)
    
  end

  # The sequenom pass value is either the string 'Unknown' or it is the combination of gender marker values.
  def get_sequenom_pass
    markers = self.well_attribute.gender_markers
    markers.is_a?(Array) ? markers.join : markers
  end

  def map_description
    return nil if map.nil?
    return nil unless map.description.is_a?(String)

    map.description
  end

  def valid_well_on_plate
    return false unless self.is_a?(Well)
    well_plate = plate
    return false unless well_plate.is_a?(Plate)
    return false if well_plate.barcode.blank?
    return false if map_id.nil?
    return false unless map.description.is_a?(String)

    true
  end
  
  def set_buffer_required(requested_volume, minimum_volume)
    if requested_volume < minimum_volume
      set_buffer_volume(calculate_buffer_required(minimum_volume, requested_volume))
    else
      set_buffer_volume(0.0)
    end
  end
  
  def calculate_buffer_required(total_volume, requested_volume)
    buffer_volume = (total_volume*100 - requested_volume*100)
    (buffer_volume.to_i.to_f)/100
  end

  def create_child_sample_tube
    sample_tube = SampleTube.create(:sample => self.sample, :map => self.map)
    AssetLink.create_edge!(self, sample_tube)

    sample_tube
  end

  def qc_data
    {:pico          => self.get_pico_pass,
     :gel           => self.get_gel_pass,
     :sequenom      => self.get_sequenom_pass,
     :concentration => self.get_concentration }
  end
  
  def self.render_class
    Api::WellIO
  end

private

  def create_well_attribute_if_not_exists
    unless self.well_attribute
      self.well_attribute = WellAttribute.create
      self.save!
    end
  end

 def buffer_required?
    get_buffer_volume > 0.0
  end

public
    
  def find_child_plate
    self.children.reverse_each do |child_asset|
      return child_asset if child_asset.is_a?(Well)
    end
    
    nil
  end

  def get_tag_instance
    self.tag_instance
  end
  
  def get_tag
    self.tag_instance.try(:tag)
  end

  def tag
    self.get_tag.try(:map_id) || ''
  end

end
