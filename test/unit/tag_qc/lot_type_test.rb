require "test_helper"

class LotTypeTest < ActiveSupport::TestCase
  context "A Lot Type" do

    context 'validating' do
      setup do
        Factory :lot
      end

      should_validate_uniqueness_of :name
    end
    should_validate_presence_of :name
    should_validate_presence_of :template_class

    should_have_many :lots
    should_belong_to :target_purpose

    context "#lot" do
      setup do
        @lot_type = Factory :lot_type
        @user = Factory :user
        @template = PlateTemplate.new
      end

      context "create" do

        setup do
          @lot = @lot_type.create!(:template=>@template,:user=>@user,:lot_number=>'123456789',:recieved_at=>'2014-02-01')
        end

        should_change('Lot.count', :by=>1) { Lot.count }

        should 'set the lot properties' do
          assert_equal @user, @lot.user
          assert_equal '123456789', @lot.lot_number
        end

      end

    end
  end

end
