require 'test_helper'

class PmbClientTest < ActiveSupport::TestCase

	attr_reader :labels

	def setup
		@labels = {"header"=> {"header_text_1"=> "header_text_1","header_text_2"=> "header_text_2"},"footer"=> {"footer_text_1"=> "footer_text_1", "footer_text_2"=> "footer_text_2"},"body"=> [{"location"=> {"location"=> "location","parent_location"=> "parent_location","barcode"=> "barcode"}},{"location"=> {"location"=> "location","parent_location"=> "parent_location","barcode"=> "barcode"}}]}
	end

	test "should have base url"  do
		assert LabelPrinter::PmbClient.base_url
	end

	test "sends a print job to the API" do

		attributes = {"printer_name" => "d304bc",
									"label_template_id" => 1,
									"labels" => labels}

		RestClient.expects(:post).with('http://localhost:9292/v1/print_jobs',
												{"data"=>{"attributes"=>attributes}}.to_json,
												content_type: "application/vnd.api+json", accept: "application/vnd.api+json")
		.returns(200)

		assert_equal 200, LabelPrinter::PmbClient.print(attributes)

	end

	test "should inform if printer is not registered" do
		RestClient.expects(:post).raises(RestClient::UnprocessableEntity)
		assert_raises(LabelPrinter::PmbException) {LabelPrinter::PmbClient.print({})}
	end

	test "should inform if pmb is down" do
		RestClient.expects(:post).raises(Errno::ECONNREFUSED)
		err = assert_raises(LabelPrinter::PmbException) {LabelPrinter::PmbClient.print({})}
		assert_equal "PrintMyBarcode service is down", err.message
	end

	test "should get label template by name from pmb" do
		  RestClient.expects(:get)
		  					.with('http://localhost:9292/v1/label_templates?filter[name]=test_template',
        							content_type: "application/vnd.api+json", accept: "application/vnd.api+json")
		  					.returns("{\"data\":[{\"id\":\"1\",\"type\":\"label_templates\",\"attributes\":{\"name\":\"test_template\"},\"relationships\":{\"label_type\":{\"data\":{\"id\":\"1\",\"type\":\"label_types\"}},\"labels\":{\"data\":[{\"id\":\"1\",\"type\":\"labels\"},{\"id\":\"2\",\"type\":\"labels\"},{\"id\":\"3\",\"type\":\"labels\"}]}}}]}")

		assert_equal 'test_template', LabelPrinter::PmbClient.get_label_template_by_name('test_template')['data'][0]['attributes']['name']
	end


end