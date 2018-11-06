require 'test_helper'

class AssetsControllerTest < ActionController::TestCase
  setup do
    @controller = AssetsController.new
    @request    = ActionController::TestRequest.create(@controller)
    @user = create :admin, api_key: 'abc'
    session[:user] = @user.id
  end

  should_require_login

  context '#create a new asset with JSON input' do
    setup do
      FactoryBot.create(:sample, name: 'phiX_for_spiked_buffers') # Required by controller
      @asset_count = Asset.count

      @barcode = { number: FactoryBot.generate(:barcode_number), prefix: 'NT' }

      @json_data = json_new_asset(@barcode)

      @request.accept = @request.env['CONTENT_TYPE'] = 'application/json'
      post :create, params: ActiveSupport::JSON.decode(@json_data)
    end

    should set_flash.to(/Asset was successfully created/)

    should 'change Asset.count by 1' do
      assert_equal 1, Asset.count - @asset_count, 'Expected Asset.count to change by 1'
    end
  end

  context 'create request with JSON input' do
    setup do
      @submission_count = Submission.count
      @asset = create(:sample_tube)
      @sample = @asset.primary_aliquot.sample

      @study = create :study
      @project = create :project, enforce_quotas: true
      @request_type = create :request_type
      @json_data = valid_json_create_request(@asset, @request_type, @study, @project)

      @request.accept = @request.env['CONTENT_TYPE'] = 'application/json'
      post :create_request, params: ActiveSupport::JSON.decode(@json_data)
    end

    should 'change Submission.count by 1' do
      assert_equal 1, Submission.count - @submission_count, 'Expected Submission.count to change by 1'
    end
    should 'set a priority' do
      assert_equal(3, Submission.last.priority)
    end
  end

  context 'print requests' do
    attr_reader :barcode_printer

    setup do
      @user = create :user
      @controller.stubs(:current_user).returns(@user)
      @barcode_printer = create :barcode_printer
      LabelPrinter::PmbClient.expects(:get_label_template_by_name).returns('data' => [{ 'id' => 15 }])
    end

    should '#print_assets should send print request' do
      asset = create :child_plate
      RestClient.expects(:post)
      post :print_assets, params: { printables: asset, printer: barcode_printer.name, id: asset.id.to_s }
    end
    should '#print_labels should send print request' do
      asset = create :sample_tube
      RestClient.expects(:post)
      post :print_labels, params: { printables: { asset.id.to_s => 'true' }, printer: barcode_printer.name, id: asset.id.to_s }
    end
  end

  def valid_json_create_request(asset, request_type, study, project)
    %(
      {
        "api_version": "#{RELEASE.api_version}",
        "api_key": "abc",
        "study_id": "#{study.id}",
        "project_id": "#{project.id}",
        "request_type_id": "#{request_type.id}",
        "count": 3,
        "priority": 3,
        "comments": "This is a request",
        "id": "#{asset.id}",
        "request": {
          "properties": {
            "library_type": "Standard",
            "fragment_size_required_from": 100,
            "fragment_size_required_to": 500,
            "read_length": 108
          }
        }
      }
    )
  end

  def json_new_asset(barcode)
    # /assets
    %(
      {
        "api_version": "#{RELEASE.api_version}",
        "api_key": "abc",
        "asset": {
          "sti_type": "SampleTube",
          "sanger_barcode": #{barcode.to_json},
          "label": "SampleTube"
        }
      }
    )
  end
end
