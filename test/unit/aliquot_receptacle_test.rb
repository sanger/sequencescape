require 'test_helper'

class ReceptacleTest < ActiveSupport::TestCase
  context 'Receptacle' do
    setup do
      @receptacle = create :receptacle
    end

    [
      ['Untagged', [:untagged_aliquot]],
      ['Single',  [:untagged_aliquot, :single_tagged_aliquot]],
      ['Dual',    [:untagged_aliquot, :dual_tagged_aliquot]]
    ].each do |name, aliquots|

      should "label #{name} assets" do
        @receptacle.aliquots = aliquots.map { |fac| create(fac, receptacle: @receptacle) }
        assert_equal name, @receptacle.tag_count_name
      end
    end

    should 'not label empty assets' do
      assert_nil @receptacle.tag_count_name
    end
  end
end
