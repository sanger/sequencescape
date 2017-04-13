require 'test_helper'

class Aliquot::ReceptacleTest < ActiveSupport::TestCase
  context 'Aliquot::Receptacle' do
    setup do
      @receptacle = create :aliquot_receptacle
    end

    [
      ['Untagged', [:untagged_aliquot]],
      ['Single',  [:untagged_aliquot, :single_tagged_aliquot]],
      ['Dual',    [:untagged_aliquot, :dual_tagged_aliquot]],
      [nil,       []]
    ].each do |name, aliquots|

      should "label #{name} assets" do
        @receptacle.aliquots = aliquots.map { |fac| create(fac, receptacle: @receptacle) }
        assert_equal name, @receptacle.tag_count_name
      end
    end
  end
end
