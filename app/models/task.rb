# A Task forms part of a {Workflow} which in turn describes the steps that form a
# {Pipeline}. Most tasks are a subclass of Task
#
# @deprecated Task form a large number of legacy pipelines in Sequencescape, however most
# more recent pipelines exist outside of Sequencescape itself.
#
# Tasks have three key methods
# {Task#render_task}: Which handles rendering the form displayed to the user
# {Task#do_task}: Which takes the parameters from the form, and performs the task in question
# {Task#partial}: Inicates which partial to render when displaying the form.
#
# @note A large number of tasks delegate a large portion of their behaviour back to the
# {WorkflowsController}. This behaviour is mostly defined in modules under {Task}.
class Task < ApplicationRecord
  belongs_to :workflow, class_name: 'Workflow', foreign_key: :pipeline_workflow_id
  has_many :descriptors, -> { order('sorter') }, dependent: :destroy

  self.inheritance_column = 'sti_type'

  # BEGIN descriptor_to_attribute, could be move into a mixin

  # TODO: move into SetDescriptorsTask
  def get_descriptor_value(name, default = nil)
    name_s = name.to_s
    descriptors.each do |desc|
      if desc.name.eql?(name_s)
        return desc.value
      end
    end
    default
  end

  def set_descriptor_value(name, value, _kind = nil)
    name_s = name.to_s
    descriptors.each do |desc|
      if desc.name.eql?(name_s)
        desc.value = value
        return
      end
    end
    descriptors << Descriptor.new(name: name_s, value: value)
  end
  # END descriptors

  # BEGIN subclass_to_attribute, could be move into a mixin
  has_many :subclass_attributes, as: :attributable, dependent: :destroy, autosave: true
  def get_subclass_attribute_value(name, default = nil)
    name_s = name.to_s
    subclass_attributes.each do |desc|
      if desc.name.eql?(name_s)
        return desc.value
      end
    end
    default
  end

  def set_subclass_attribute_value(name, value, _kind = nil)
    name_s = name.to_s
    subclass_attributes.each do |desc|
      if desc.name.eql?(name_s)
        desc.value = value
        return
      end
    end
    subclass_attributes << SubclassAttribute.new(name: name_s, value: value)
  end

  def self.init_class
    return if @init_done

    @init_done = true
    @subclass_attributes = {}
    @subclass_attributes_ordered_names = []
  end

  def self.get_subclass_attribute_options(name)
    init_class
    @subclass_attributes[name]
  end

  def get_subclass_attribute_options(name)
    self.class.get_subclass_attribute_options(name)
  end

  def self.get_subclass_attributes
    init_class
    @subclass_attributes_ordered_names
  end

  def get_subclass_attributes
    self.class.get_subclass_attributes
  end

  def self.set_subclass_attribute(name, options = {})
    init_class
    raise ArgumentError, "subclass attribute #{name} already in use" if @subclass_attributes.include? name

    @subclass_attributes[name] = options
    @subclass_attributes_ordered_names << name

    kind = options[:kind]
    cast = options[:cast]
    default_value = options[:default]

    define_method(name) do
      value = get_subclass_attribute_value name, default_value # we love closure :)
      value and case cast
                when :int
                  value.to_i
                else
                  value
                end
    end

    define_method("#{name}=") do |value|
      set_subclass_attribute_value(name, value, kind)
    end
  end

  # END of subclass_to_attiribuet

  class RenderElement
    attr_reader :request, :asset
    def initialize(request)
      @request = request
      @asset = request.asset
    end
  end

  def partial
  end

  def included_for_do_task
    %i[requests pipeline lab_events]
  end

  def included_for_render_task
    %i[requests pipeline lab_events]
  end

  def render_task(controller, params)
    controller.render_task(self, params)
  end

  def create_render_element(request)
    request && RenderElement.new(request)
  end

  def do_task(_controller, _params)
    raise NotImplementedError, "Please Implement a do_task for #{self.class.name}"
  end

  def sub_events_for(_event)
    []
  end

  def find_batch(batch_id)
    Batch.includes(:requests, :pipeline, :lab_events).find(batch_id)
  end

  def find_batch_requests(batch_id)
    find_batch(batch_id).ordered_requests
  end
end
