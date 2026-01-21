# frozen_string_literal: true

require 'test_helper'

class PmbClientTest < ActiveSupport::TestCase
  attr_reader :labels

  def setup
    @labels = {
      'header' => {
        'header_text_1' => 'header_text_1',
        'header_text_2' => 'header_text_2'
      },
      'footer' => {
        'footer_text_1' => 'footer_text_1',
        'footer_text_2' => 'footer_text_2'
      },
      'body' => [
        { 'location' => { 'location' => 'location', 'parent_location' => 'parent_location', 'barcode' => 'barcode' } },
        { 'location' => { 'location' => 'location', 'parent_location' => 'parent_location', 'barcode' => 'barcode' } }
      ]
    }
  end

  test 'should have base url' do
    assert LabelPrinter::PmbClient.base_url
  end

  test 'sends a print job to the API' do
    attributes = { 'printer_name' => 'd304bc', 'label_template_id' => 1, 'labels' => labels }

    RestClient
      .expects(:post)
      .with(
        'http://localhost:9292/v2/print_jobs',
        { 'print_job' => attributes }.to_json,
        content_type: 'application/vnd.api+json',
        accept: 'application/vnd.api+json'
      )
      .returns(201)

    assert_equal 201, LabelPrinter::PmbClient.print(attributes)
  end

  test 'should inform if attributes are missing' do
    RestClient.expects(:post).raises(RestClient::UnprocessableEntity)
    assert_raises(LabelPrinter::PmbException) { LabelPrinter::PmbClient.print({}) }
  end

  test 'should inform if Pmb is too busy' do
    RestClient.expects(:post).raises(RestClient::ServiceUnavailable)
    assert_raises(LabelPrinter::PmbException) { LabelPrinter::PmbClient.print({}) }
  end

  test 'should inform if something is wrong with Pmb' do
    RestClient.expects(:post).raises(RestClient::InternalServerError)
    assert_raises(LabelPrinter::PmbException) { LabelPrinter::PmbClient.print({}) }
  end

  test 'should inform if pmb is down' do
    RestClient.expects(:post).raises(Errno::ECONNREFUSED)
    err = assert_raises(LabelPrinter::PmbException) { LabelPrinter::PmbClient.print({}) }
    assert_equal 'service is down', err.message
  end

  test 'should get label template by name from pmb' do
    RestClient
      .expects(:get)
      .with(
        'http://localhost:9292/v2/label_templates?filter[name]=test_template',
        {
          content_type: 'application/vnd.api+json',
          accept: 'application/vnd.api+json'
        }
      )
      .returns(
        {
          data: [
            {
              id: '1',
              type: 'label_templates',
              attributes: {
                name: 'test_template'
              },
              relationships: {
                label_type: {
                  data: {
                    id: '1',
                    type: 'label_types'
                  }
                },
                labels: {
                  data: [{ id: '1', type: 'labels' }, { id: '2', type: 'labels' }, { id: '3', type: 'labels' }]
                }
              }
            }
          ]
        }.to_json
      )

    assert_equal 'test_template',
                 LabelPrinter::PmbClient.get_label_template_by_name('test_template')['data'][0]['attributes']['name']
  end

  test 'should register printer in pmb if it was not there' do
    RestClient
      .expects(:get)
      .with(
        'http://localhost:9292/v2/printers?filter[name]=test_printer',
        content_type: 'application/vnd.api+json',
        accept: 'application/vnd.api+json'
      )
      .returns('{"data":[]}')
    RestClient
      .expects(:post)
      .with(
        'http://localhost:9292/v2/printers',
        { 'data' => { 'attributes' => { 'name' => 'test_printer', 'printer_type' => 'squix' } } }.to_json,
        content_type: 'application/vnd.api+json',
        accept: 'application/vnd.api+json'
      )
      .returns(201)
    assert_equal 201, LabelPrinter::PmbClient.register_printer('test_printer', 'squix')

    RestClient
      .expects(:get)
      .with(
        'http://localhost:9292/v2/printers?filter[name]=test_printer',
        content_type: 'application/vnd.api+json',
        accept: 'application/vnd.api+json'
      )
      .returns('{"data":[{"id":"49","type":"printers","attributes":{"name":"test_printer","protocol":"LPD"}}]}')
    assert_not LabelPrinter::PmbClient.register_printer('test_printer', 'squix')
  end

  test 'should return pretty errors with new json' do
    errors =
      # rubocop:todo Layout/LineLength
      '{"errors":[{"source":{"pointer":"/data/attributes/printer"},"detail":"does not exist"}, {"source":{"pointer":"/data/attributes/label_template"},"detail":"does not exist"}]}'

    # rubocop:enable Layout/LineLength
    pretty_errors = 'Printer does not exist; Label template does not exist'
    assert_equal pretty_errors, LabelPrinter::PmbClient.pretty_errors(errors)
  end

  test 'should return pretty errors with old json' do
    errors = '{"errors":{"printer":["Something is wrong","Something else is wrong"],"labels":["Something is wrong"]}}'
    pretty_errors = 'Printer: Something is wrong, Something else is wrong; Labels: Something is wrong'
    assert_equal pretty_errors, LabelPrinter::PmbClient.pretty_errors(errors)
  end
end
