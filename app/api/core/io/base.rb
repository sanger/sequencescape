# Core class for {file:docs/api_v1.md API V1} IO, which effectively acts as a view layer.
# New IO should be placed in `app/api/io/` and should inherit from Core::IO::Base.
# All IO are in the {::Io} namespace.
#
# @example BaitLibrary
#   class Io::BaitLibrary < Core::Io::Base
#     set_model_for_input(::BaitLibrary)
#     set_json_root(:bait_library)
#     define_attribute_and_json_mapping("
#       bait_library_supplier.name  => supplier.name
#              supplier_identifier  => supplier.identifier
#                             name  => name
#                   target_species  => target.species
#           bait_library_type.name  => bait_library_type
#     ")
#   end
#
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
