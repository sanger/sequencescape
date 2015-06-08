#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
require "test_helper"

class PipelineSerializerTest < ActiveSupport::TestCase
  context "PipelineSerializer" do
    setup do
      class Test
        def json
          "{
            \"name\":\"Illumina-C Library preparation Testing\",
            \"sti_type\":\"LibraryCreationPipeline\",
            \"asset_type\": \"LibraryTube\",
            \"sorter\": 0,
            \"automated\": false,
            \"active\": true,
            \"location_name\": \"Library creation freezer\",
            \"request_types_keys\": [\"library_creation\", \"illumina_c_library_creation\"],
            \"workflow\": {
              \"locale\": \"External\",
              \"tasks\": [
                { \"class\": \"TagGroupsTask\",
                  \"name\": \"Tag Groups\",
                  \"sorted\": 1,
                  \"lab_activity\": true },
                { \"class\": \"AssignTagsTask\",
                  \"name\": \"Assign Tags\",
                  \"sorted\": 2,
                  \"lab_activity\": true },
                { \"class\": \"SetDescriptorsTask\",
                  \"name\": \"Initial QC\",
                  \"sorted\": 3,
                  \"batched\": false,
                  \"lab_activity\": true },
                { \"class\": \"SetDescriptorsTask\",
                  \"name\": \"Gel\",
                  \"sorted\": 4,
                  \"batched\": false,
                  \"lab_activity\": true },
                { \"class\": \"SetDescriptorsTask\",
                  \"name\": \"Characterisation\",
                  \"sorted\": 5,
                  \"batched\": true,
                  \"lab_activity\": true }
              ]
            },
            \"request_information_type_labels\": [\"Fragment size required (from)\", \"Fragment size required (to)\",
               \"Read length\", \"Library type\"]
          }"
        end

        def json_seq_pipeline
          "{
            \"name\":\"Cluster formation SE (no controls) - COPY\",
            \"sti_type\":\"SequencingPipeline\",
            \"asset_type\": \"Lane\",
            \"sorter\": 2,
            \"automated\": false,
            \"active\": true,
            \"location_name\": \"Cluster formation freezer\",
            \"request_types_keys\": [\"illumina_a_single_ended_sequencing\", \"illumina_b_single_ended_sequencing\",
               \"illumina_c_single_ended_sequencing\", \"single_ended_sequencing\"],
            \"workflow\": {
              \"locale\": \"Internal\",
              \"item_limit\": 8,
              \"tasks\": [
                { \"class\": \"SetDescriptorsTask\",
                  \"name\": \"Specify Dilution Volume\",
                  \"sorted\": 1,
                  \"batched\": true },
                { \"class\": \"SetDescriptorsTask\",
                  \"name\": \"Cluster generation\",
                  \"sorted\": 3,
                  \"batched\": true,
                  \"interactive\": false,
                  \"per_item\": false,
                  \"lab_activity\": true },
                { \"class\": \"SetDescriptorsTask\",
                  \"name\": \"Quality control\",
                  \"sorted\": 4,
                  \"batched\": true,
                  \"interactive\": false,
                  \"per_item\": false,
                  \"lab_activity\": true },
                { \"class\": \"SetDescriptorsTask\",
                  \"name\": \"Lin/block/hyb/load\",
                  \"sorted\": 5,
                  \"batched\": true,
                  \"interactive\": false,
                  \"per_item\": false,
                  \"lab_activity\": true }
              ]
            },
            \"request_information_type_labels\": [\"Read length\", \"Library type\", \"Vol.\"]
          }"
        end

      end

      @test = Test.new
    end

    should "generate a parseable json from an object" do
      assert_equal true, !JsonSerializers::PipelineSerializer.to_json(Pipeline.first).nil?
    end

    should "create a new pipeline from a json" do
      JsonSerializers::PipelineSerializer.build(@test.json).save!
      pipeline = Pipeline.find_by_name("Illumina-C Library preparation Testing")
      assert_equal true, !pipeline.nil?
      assert_equal 2, pipeline.request_types.length
      assert_equal "library_creation", pipeline.request_types.first.key
    end

    should "all the content of the pipeline has been loaded from the json used for initializing itself" do
      [@test.json, @test.json_seq_pipeline].each do |json|
        JsonSerializers::PipelineSerializer.build(json).save!
        object_a = JSON.parse(json)
        object_b = JSON.parse(JsonSerializers::PipelineSerializer.to_json(Pipeline.find_by_name(object_a["name"])))

        diff_tasks = object_a["workflow"]["tasks"].each_with_index.map do |t, pos|
          t.to_a - object_b["workflow"]["tasks"][pos].to_a
        end.flatten

        assert_equal [], diff_tasks

        object_a["workflow"].delete("tasks")
        object_b["workflow"].delete("tasks")

        diff_workflow = (object_a["workflow"].to_a - object_b["workflow"].to_a).flatten

        assert_equal [], diff_workflow

        object_a.delete("workflow")
        object_b.delete("workflow")

        assert_equal [], (object_a.to_a - object_b.to_a)
      end
    end

    should "modifies data from the json" do
      obj = JSON.parse(@test.json)
      obj["name"] = "My new pipeline"
      obj["workflow"]["name"]="My new workflow"

      JsonSerializers::PipelineSerializer.build(obj.to_json).save!
      pipeline = Pipeline.find_by_name("My new pipeline")
      assert_equal true, !pipeline.nil?
    end

    should "duplicates a pipeline from another one in the database" do
      original_pipeline = Pipeline.first
      obj = JSON.parse(JsonSerializers::PipelineSerializer.to_json(original_pipeline))
      obj["name"] = "My duplicate pipeline from #{original_pipeline.name}"
      obj["workflow"]["name"]="My duplicate workflow from #{original_pipeline.name}"

      JsonSerializers::PipelineSerializer.build(obj.to_json).save!
      pipeline = Pipeline.find_by_name("My duplicate pipeline from #{original_pipeline.name}")
      assert_equal true, !pipeline.nil?
    end

  end
end
