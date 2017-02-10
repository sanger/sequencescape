# Used in tests to provide a pool of predicatable uuids
class UuidStore
  def initialize
    @store = Hash.new { |h, i| h[i] = [] }
  end

  # Set or retrieve the next uuid for a given resource type
  #
  # @param [Class] resource_type Base class of the resource (eg. Asset for a Well )
  # @param [String] uuid Optional: String of the next uuid provided. If none is set, shift the first one off the list.
  # @return [String] A uuid
  def next_uuid_for(resource_type, uuid = nil)
    if uuid
      @store[resource_type] << uuid
      uuid
    else
      @store[resource_type].shift
    end
  end

  def clear!
    @store = Hash.new { |h, i| h[i] = [] }
  end
end
After do |_s|
  Uuid.store_for_tests.try(:clear!)
end
