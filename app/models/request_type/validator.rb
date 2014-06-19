##
# A request type validator belongs to a request type, and is responsible for
# validating a single request option
# request_option => The option that will be validated
# valid_options  => A serialized object that responds to include? Returning true if the option is present
class RequestType::Validator < ActiveRecord::Base

  class LibraryTypeValidator
    attr_reader :request_type_id
    def initialize(request_type_id)
      @request_type_id = request_type_id
    end
    def request_type
      RequestType.find(request_type_id)
    end
    def include?(option)
      request_type.library_types.map(&:name).include?(option)
    end
    def default
      request_type.default_library_type.try(:name)
    end
  end

  belongs_to :request_type
  validates_presence_of :request_type, :request_option, :valid_options
  serialize :valid_options

  def include?(option)
    valid_options.include?(option)
  end

  def default
    valid_options.respond_to?(:default) ? valid_options.default : nil
  end

  def type_cast
    {
      'read_length' => :to_i
    }[request_option]
  end
end
