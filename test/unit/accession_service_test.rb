require File.dirname(__FILE__) + '/../test_helper'

class AccessionServiceTest < ActiveSupport::TestCase
  # temporary test for hotfix
  context "A sample with a strain" do
    setup do
      @study = Factory :study
      @sample = Factory :sample, :studies => [@study]
      @sample.sample_metadata.sample_strain_att  = "my strain"
    end


    should "expose strain in ERA xml" do
      strain_tag = nil
      acc = Accessionable::Sample.new(@sample)
      acc.tags.each do |tag|
        if tag.label  == "Strain"
          strain_tag = {:tag => tag.label, :value => tag.value }
          break
        end
      end
      assert_equal({:tag => "Strain", :value => "my strain" }, strain_tag)
    end
  end

  context "A sample with a gender" do
    setup do
      @study = Factory :managed_study
      @sample = Factory :sample, :studies => [@study]
      @sample.sample_metadata.gender  = "male"
    end


    should "expose gender in EGA xml" do
      gender_tag = nil
      acc = Accessionable::Sample.new(@sample)
      acc.tags.each do |tag|
        if tag.label  == "Gender"
          gender_tag = {:tag => tag.label, :value => tag.value }
          break
        end
      end
      assert_equal({:tag => "Gender", :value => "male" }, gender_tag)
    end
  end
end
