
class ::Core::Io::Base
  extend ::Core::Logging
  extend ::Core::Benchmarking
  extend ::Core::Io::Base::EagerLoadingBehaviour
  extend ::Core::Io::Base::JsonFormattingBehaviour

  class << self
    def map_parameters_to_attributes(*_args)
      {}
    end
    private :map_parameters_to_attributes
  end
end
