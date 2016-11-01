require 'test_helper'

class DynamicOptionsTest < ActiveSupport::TestCase

  setup do
    @dynamic_options = SampleManifestExcel::DynamicOption.new(klass: LibraryType, scope: :alphabetical, identifier: :name)
  end

  test 'should convert to an array' do
    assert_instance_of Array, @dynamic_options.to_a
  end

  test 'should resolve to an array of identifier, filtered by scope' do
    assert_equal LibraryType.alphabetical.pluck(:name), @dynamic_options.to_a
  end

  test 'should be lazily converted' do
    create :library_type, name: 'New library type'
    assert_include @dynamic_options.to_a, 'New library type'
  end
end
