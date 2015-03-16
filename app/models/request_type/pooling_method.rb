class RequestType::PoolingMethod < ActiveRecord::Base

  has_many :request_types
  validates_presence_of :pooling_behaviour
  serialize :pooling_options

  set_table_name('pooling_methods')

  def after_initialize
    import_behaviour
  end

  def import_behaviour
    return if pooling_behaviour.nil?
    behavior_module = "RequestType::PoolingMethod::#{pooling_behaviour}".constantize
    self.class_eval do
      include(behavior_module)
    end
  end

  def pooling_behaviour=(*params)
    super
    import_behaviour
  end

end
