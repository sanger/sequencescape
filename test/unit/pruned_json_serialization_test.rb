#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
require "test_helper"

class PrunedJsonSerializationTest < ActiveSupport::TestCase
  context "PrunedJsonSerialization" do
    setup do
      class Test
        include PrunedJsonSerialization
        def json
      "{
         \"transcoded_class\":\"LibraryCreationPipeline\",
         \"active\":true,
         \"asset_type\":\"LibraryTube\",
         \"automated\":false,
         \"control_request_type\":{
            \"transcoded_class\":\"RequestType\",
            \"transcoded_find_by_key\":\"illumina_c_library_creation_control\"
         },
         \"externally_managed\":false,
         \"group_by_parent\":null,
         \"group_by_study_to_delete\":true,
         \"group_by_submission_to_delete\":null,
         \"group_name\":null,
         \"location\":{
            \"transcoded_class\":\"Location\",
            \"transcoded_find_by_name\":\"Library creation freezer\"   },
         \"max_number_of_groups\":null,
         \"max_size\":null,
         \"min_size\":null,
         \"multiplexed\":null,
         \"name\":\"Testing Illumina-C Library preparation\",
         \"next_pipeline\":null,
         \"paginate\":false,
         \"previous_pipeline\":null,
         \"sorter\":0,
         \"sti_type\":\"LibraryCreationPipeline\",
         \"summary\":true,
         \"workflow\":{
            \"transcoded_class\":\"LabInterface::Workflow\",
            \"item_limit\":null,
            \"locale\":\"External\",
            \"name\":\"Testing Library preparation\",
            \"tasks\":[
               {
                  \"transcoded_class\":\"SetDescriptorsTask\",
                  \"batched\":null,
                  \"interactive\":null,
                  \"lab_activity\":true,
                  \"location\":null,
                  \"name\":\"Initial QC\",
                  \"per_item\":null,
                  \"sorted\":1,
                  \"sti_type\":\"SetDescriptorsTask\",
                  \"descriptors\":[
                    {
                      \"transcoded_class\":\"Descriptor\",
                      \"kind\":\"Selection\",
                      \"name\":\"Strips to create\",
                      \"required\":null,
                      \"selection\":[1,2,4,6,12],
                      \"sorter\":null,
                      \"value\":null
                    },{
                        \"transcoded_class\":\"Descriptor\",
                        \"kind\":null,
                        \"name\":\"Strip Tube Purpose\",
                        \"required\":null,
                        \"selection\":null,
                        \"sorter\":null,
                        \"value\":\"Strip Tube Purpose\"
                    }
                  ]
               },
               {
                  \"transcoded_class\":\"SetDescriptorsTask\",
                  \"batched\":null,
                  \"interactive\":false,
                  \"lab_activity\":true,
                  \"location\":null,
                  \"name\":\"Gel\",
                  \"per_item\":false,
                  \"sorted\":2,
                  \"sti_type\":\"SetDescriptorsTask\"
               },
               {
                  \"transcoded_class\":\"SetDescriptorsTask\",
                  \"batched\":true,
                  \"interactive\":false,
                  \"lab_activity\":true,
                  \"location\":null,
                  \"name\":\"Characterisation\",
                  \"per_item\":false,
                  \"sorted\":3,
                  \"sti_type\":\"SetDescriptorsTask\"
               }
            ]
         },
         \"request_types\":[
            {
               \"transcoded_class\":\"RequestType\",
               \"transcoded_find_by_key\":\"library_creation\"
            },
            {
               \"transcoded_class\":\"RequestType\",
               \"transcoded_find_by_key\":\"illumina_c_library_creation\"
            }
         ]
      }"
        end

      end

      @test = Test.new
    end

    should "generate a parseable json from an object" do
      assert_equal true, !PrunedJsonSerialization.render(Pipeline.first).nil?
    end

    should "create a new pipeline from a json" do
      assert_equal true, PrunedJsonSerialization.build(@test.json)
      pipeline = Pipeline.find_by_name("Testing Illumina-C Library preparation")
      assert_equal true, !pipeline.nil?
      assert_equal 2, pipeline.request_types.length
      assert_equal "library_creation", pipeline.request_types.first.key
    end

    should "duplicate a pipeline from an old one" do
      obj = PrunedJsonSerialization.pipeline_attribute_hash(Pipeline.first)
      obj["name"] = "My new pipeline"
      obj["workflow"]["name"]="My new workflow"
      assert_equal true, PrunedJsonSerialization.build(obj.to_json)
      pipeline = Pipeline.find_by_name("My new pipeline")
      assert_equal true, !pipeline.nil?
      assert_equal obj["workflow"]["name"], pipeline.workflow.name
    end
  end
end
