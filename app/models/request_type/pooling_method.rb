class RequestType::PoolingMethod < ApplicationRecord # rubocop:todo Style/Documentation
  has_many :request_types
  validates :pooling_behaviour, presence: true
  serialize :pooling_options

  self.table_name = ('pooling_methods')

  after_initialize :import_behaviour

  def import_behaviour
    return if pooling_behaviour.nil?

    behavior_module = "RequestType::PoolingMethod::#{pooling_behaviour}".constantize
    class_eval { include(behavior_module) }
  end

  def pooling_behaviour=(*params)
    super
    import_behaviour
  end
end
