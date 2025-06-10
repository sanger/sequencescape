# frozen_string_literal: true
require 'test_helper'

class ElementAvitiSequencingPipelineTest < ActiveSupport::TestCase
  setup do
    @pipeline =
      ElementAvitiSequencingPipeline.new(workflow: Workflow.new, request_types: [create(:sequencing_request_type)])

    @batch = create(:batch, pipeline: @pipeline)

    # Attach request and metadata
    @request =
      create(
        :sequencing_request,
        batch: @batch,
        request_metadata_attributes: {
          read_length: 75,
          fragment_size_required_from: 100,
          fragment_size_required_to: 200,
          requested_flowcell_type: 'ElementAvitiFlowcell'
        }
      )

    # Force target_asset if needed
    @flowcell = create(:flowcell, batch: @batch)
  end

  test 'generates valid flowcell XML message on post_release_batch' do
    assert_difference('Messenger.count', 1) { @pipeline.post_release_batch(@batch, create(:user)) }

    messenger = Messenger.last
    assert_equal @batch, messenger.target
    assert_equal 'FlowcellIo', messenger.template

    # Optionally render the actual message and assert content
    xml = MessengerRenderer.new(messenger).render # or however your app renders messages
    assert_includes xml, '<flowcell>'
    assert_includes xml, '<lane'
    assert_includes xml, @request.sample.sample_uuid
    assert_includes xml, @request.study.study_uuid
    assert_includes xml, 'Element Aviti' # Subclass-specific check
  end

  test 'post_release_batch generates correct flowcell message' do
    user = create(:user)
    batch = create(:batch, pipeline: ElementAvitiSequencingPipeline.create!(workflow: create(:workflow)))
    request = create(:sequencing_request, batch:)

    # This should trigger the Messenger creation
    ElementAvitiSequencingPipeline.new.post_release_batch(batch, user)

    messenger = Messenger.last
    message = messenger.as_json

    # Basic structure checks
    assert message.key?('flowcell'), 'Missing flowcell root key'
    assert_equal configatron.amqp.lims_id, message['lims']

    flowcell = message['flowcell']
    assert_equal batch.id, flowcell['flowcell_id']
    assert flowcell['lanes'].any?, 'Expected at least one lane in flowcell'

    sample = flowcell['lanes'].first['samples'].first
    assert_equal request.sample.sample_uuid, sample['sample_uuid']
  end
end
