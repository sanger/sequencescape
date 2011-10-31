# It associates a name to a pre-filled submission (subclass) and a serialized set of attributes 
# We could have use a Prototype Factory , and so just associate a name to existing submission
# but that doesn't work because the submission prototype doesn't pass the validation stage.
# Anyway that's basically a prototype factory
class SubmissionTemplate < ActiveRecord::Base
  include Uuid::Uuidable

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_presence_of :submission_class_name

  serialize :submission_parameters
  acts_as_audited :on => [:destroy, :update]

  def create!(attributes)
    self.new_submission(attributes).tap do |submission|
      yield(submission) if block_given?
      submission.save! 
    end
  end

  def create_with_submission!(attributes)
    self.create!(attributes) do |order|
      order.create_submission
    end
  end

  # create a new submission of the good subclass and with pre-set attributes
  def new_submission(params={})
    attributes = submission_attributes.deep_merge(params)
    infos      = SubmissionTemplate.unserialize(attributes.delete(:input_field_infos))

    submission_class.new(attributes).tap do |submission|
      submission.template_name = self.name
      submission.set_input_field_infos(infos) unless infos.nil?
    end
  end

  # TODO[xxx]: This is a hack just so I can move forward but the request_types stuff should come directly
  def submission_attributes
    return {} if self.submission_parameters.nil?
    submission_attributes = Marshal.load(Marshal.dump(self.submission_parameters))  # Deep clone
    submission_attributes[:request_types] = submission_attributes[:request_type_ids_list].flatten
    submission_attributes
  end
  private :submission_attributes

  # create a new template from a submission
  def self.new_from_submission(name, submission)
    submission_template = new(:name => name)
    submission_template.update_from_submission(submission)
    return submission_template
  end

  def update_from_submission(submission)
    self.submission_class_name = submission.class.name
    self.submission_parameters = submission.template_parameters
  end

  def submission_class
    klass = submission_class_name.constantize
    #TODO[mb14] Hack. This is to avoid to have to rename it in database or seen 
    #The hack is not needed for subclasses as they inherits from Order
    klass == Submission ? Order  : klass
  end

  private 

  def self.unserialize(object)
    if object.respond_to? :map
      return object.map { |o| unserialize(o) }
    elsif object.is_a?(YAML::Object)
      return object.class.constantize.new(object.ivars)
    else 
      return object
    end
  end
end
