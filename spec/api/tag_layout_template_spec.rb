# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/limber_shared_context'

describe '/api/1/tag_layout_templates' do
  include_context 'a limber target plate with submissions'

  subject { '/api/1/tag_layout_templates' }

  let(:authorised_app) { create :api_application }
  let(:user) { create :user }

  describe '#get' do
    let(:response_body) do
      %(
        {
          "actions":{
            "read":"http://www.example.com/api/1/tag_layout_templates/1",
            "first":"http://www.example.com/api/1/tag_layout_templates/1",
            "last":"http://www.example.com/api/1/tag_layout_templates/1"
          },
          "size":#{TagLayoutTemplate.count},
          "tag_layout_templates":[
            {
              "actions":{
                "read":"http://www.example.com/api/1/#{example_template_uuid}",
                "create":"http://www.example.com/api/1/#{example_template_uuid}"
              },
              "uuid":"#{example_template_uuid}",
              "direction":"column",
              "name":"#{example_template.name}",
              "tag_group":{
                "actions":{
                  "read":"http://www.example.com/api/1/#{tag_group_uuid}"
                },
                "uuid":"#{tag_group_uuid}",
                "name":"#{example_group.name}",
                "tags":{"1":"","2":""}
              },
              "tag2_group": null,
              "walking_by":"wells in pools"
            }
          ]
        }
      )
    end
    let(:response_code) { 200 }

    let!(:example_template) { create :tag_layout_template, tags: ['', ''] }

    let(:example_template_uuid) { example_template.uuid }
    let(:example_group) { example_template.tag_group }
    let(:tag_group_uuid) { example_template.tag_group.uuid }

    it 'returns an index' do
      example_template
      api_request :get, subject
      expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
      expect(status).to eq(response_code)
    end
  end

  describe '/api/1/template-uuid' do
    subject { "/api/1/#{example_template.uuid}" }

    let(:example_template) do
      create :entire_plate_tag_layout_template, name: 'Test Example', tags: %w[AAA TTT]
    end
    let(:example_tag_group) { example_template.tag_group }

    describe '#get' do
      let(:response_body) do
        %({
          "tag_layout_template":{
            "actions":{
              "read":"http://www.example.com/api/1/#{example_template.uuid}",
              "create":"http://www.example.com/api/1/#{example_template.uuid}"
            },
            "uuid":"#{example_template.uuid}",
            "direction":"column",
            "name":"Test Example",
            "tag_group":{
              "actions":{"read":"http://www.example.com/api/1/#{example_tag_group.uuid}"},
              "uuid":"#{example_tag_group.uuid}",
              "name":"Test Example",
              "tags":{"1":"AAA","2":"TTT"}
            },
            "tag2_group": null,
            "walking_by":"wells of plate"
          }
        })
      end
      let(:response_code) { 200 }

      it 'returns the expected json' do
        api_request :get, subject
        expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
        expect(status).to eq(response_code)
      end
    end

    describe '#post' do
      let(:target) { create :plate }
      let(:payload) do
        %({"tag_layout":{ "plate": "#{target.uuid}", "user": "#{user.uuid}"}})
      end

      let(:response_body) do
        %({
          "tag_layout": {
            "actions": {},
            "plate": {
              "actions": {
                "read": "http://www.example.com/api/1/#{target.uuid}"
              }
            },
            "direction": "column",

            "tag_group": {
              "name": "#{example_template.name}",
              "tags": {
                "1": "AAA",
                "2": "TTT"
              }
            },
            "tag2_group": null
          }
        })
      end
      let(:response_code) { 201 }

      it 'returns the expected json' do
        api_request :post, subject, payload
        expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
        expect(status).to eq(response_code)
      end
    end
  end
end
