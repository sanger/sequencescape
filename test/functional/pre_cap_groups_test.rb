require "test_helper"

class PreCapGroupsTest < ActiveSupport::TestCase

  def with_pools(*pools)
    t = Time.now
    pools.each_with_index do |well_locs,index|
      @plate.wells.located_at(well_locs).each do |well|
        Factory(:pulldown_isc_request, {
          :asset => well,
          :pre_capture_pool => @pools[index],
          :created_at => t + index
        })
      end
    end
  end

  context "A plate" do
    setup do
      @plate = Factory :pooling_plate
      @pools = (0..3).map do |i|
        pool = Factory :pre_capture_pool
        pool.uuid_object.update_attributes!(:external_id=>"00000000-0000-0000-0000-00000000000#{i}")
        pool
      end
    end

    context "with two distinct pools" do

      setup do
        with_pools(['A1','B1','C1'],['D1','E1','F1'])
      end

      should "report two pools" do

        assert_equal 6, @plate.wells.count
        assert_equal([
          ['00000000-0000-0000-0000-000000000000',['A1','B1','C1']],
          ['00000000-0000-0000-0000-000000000001',['D1','E1','F1']]
          ], @plate.pre_cap_groups.map {|pool,options| [pool,options[:wells].sort ]})
      end
    end

    context "with overlapping distinct pools" do

      setup do
        with_pools(['A1','B1','C1'],['D1','E1','F1'],['A1','D1'])
      end

      context "when all are pending" do

        should "still report all the pools" do

          assert_equal 6, @plate.wells.count
          assert_equal([
            ['00000000-0000-0000-0000-000000000000',['A1','B1','C1']],
            ['00000000-0000-0000-0000-000000000001',['D1','E1','F1']],
            ['00000000-0000-0000-0000-000000000002',['A1','D1']]
            ], @plate.pre_cap_groups.map {|pool,options| [pool,options[:wells].sort ]})
        end
      end

      context "when some are started" do
        setup do
          @pools[0,2].each {|pl| pl.requests.each {|r| r.update_attributes!(:state=>'started')}}
        end

        should "report the unstarted pool" do

          assert_equal 6, @plate.wells.count
          assert_equal([
            ['00000000-0000-0000-0000-000000000002',['A1','D1']]
            ], @plate.pre_cap_groups.map {|pool,options| [pool,options[:wells].sort ]})
        end
      end
    end
  end
end
