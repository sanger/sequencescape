require 'pry'
require 'rails_helper'
require 'support/barcode_helper'

describe '/api/1/extraction_attributes' do
  context '#post' do
    let(:user) { create :user }
    let(:authorised_app) { create :api_application }
    let(:target_plate) { create :plate_with_empty_wells }
    subject { "/api/1/#{target_plate.uuid}/extraction_attributes" }
    let(:response_code) { 201 }

    it 'supports attributes update on a plate' do
      sample_tube = create :sample_tube
      payload = %{{
          "extraction_attribute":{
            "created_by": "#{user.name}",
            "attributes_update": [
              {"sample_tube_uuid": "#{sample_tube.uuid}", "location": "A1"}
            ]
          }
        }}
      authorized_api_request :post, subject, payload
      expect(JSON.parse(response.body)).to include_json(JSON.parse(payload))
      expect(status).to eq(response_code)
    end

    context '#racking' do
      let(:sample_tube) { create :sample_tube }
      let(:sample_tube2) { create :sample_tube }

      let(:payload) do
        %{{
          "extraction_attribute":{
            "created_by": "#{user.name}",
            "attributes_update": [
              {"sample_tube_uuid": "#{sample_tube.uuid}", "location": "A1"},
              {"sample_tube_uuid": "#{sample_tube2.uuid}", "location": "B1"}
            ]
          }
        }}
      end
      context 'with an empty plate' do
        it 'racks a tube into a well' do
          authorized_api_request :post, subject, payload
          expect(status).to eq(response_code)
          expect(target_plate.wells.located_at('A1').first.samples).to eq(sample_tube.samples)
          expect(target_plate.wells.located_at('B1').first.samples).to eq(sample_tube2.samples)
        end
        it 'does not rack a tube into a well if the tube does not exist' do
          sample_tube2.destroy
          authorized_api_request :post, subject, payload
          expect(target_plate.wells.located_at('B1').first.samples.count).to_not eq(1)
        end
      end
      context 'with a plate with wells' do
        let(:target_plate) { create :plate_with_tagged_wells }
        subject { "/api/1/#{target_plate.uuid}/extraction_attributes" }

        it 'does rack a tube into a well that already has a sample in it' do
          authorized_api_request :post, subject, payload
          expect(status).to eq(response_code)
          expect(target_plate.wells.located_at('A1').first.samples.count).to eq(2)
          expect(target_plate.wells.located_at('A1').first.samples.include?(sample_tube.samples.first)).to eq(true)
        end
        it 'does not rack a tube in the well if the well already contains the sample for this tube' do
          authorized_api_request :post, subject, payload
          expect(status).to eq(response_code)
          expect(target_plate.wells.located_at('A1').first.samples.count).to eq(2)
          expect(target_plate.wells.located_at('A1').first.samples.include?(sample_tube.samples.first)).to eq(true)
          authorized_api_request :post, subject, payload
          expect(target_plate.wells.located_at('A1').first.samples.count).to eq(2)
          expect(target_plate.wells.located_at('A1').first.samples.include?(sample_tube.samples.first)).to eq(true)
        end
      end
    end

    context '#reracking' do
      let(:previous_plate) { create :plate_with_tagged_wells }
      let(:previous_plate2) { create :plate_with_tagged_wells }
      let(:target_plate) { create :plate_with_empty_wells }
      let(:well1) { previous_plate.wells.first }
      let(:well2) { previous_plate2.wells.first }
      subject { "/api/1/#{target_plate.uuid}/extraction_attributes" }
      let(:payload) do
        %{{
          "extraction_attribute":{
            "created_by": "#{user.name}",
            "attributes_update": [
              {
                "uuid": "#{well1.uuid}",
                "location": "B1"
              },
              {
                "uuid": "#{well2.uuid}",
                "location": "A1"
              }
            ]
          }
        }}
      end

      it 'reracks a well into another plate' do
        samples_from_first_plate = previous_plate.wells.located_at('A1').first.samples
        samples_from_second_plate = previous_plate2.wells.located_at('A1').first.samples
        authorized_api_request :post, subject, payload

        expect(status).to eq(response_code)
        expect(target_plate.wells.located_at('B1').first.samples).to eq(samples_from_first_plate)
        expect(target_plate.wells.located_at('A1').first.samples).to eq(samples_from_second_plate)
      end

      context 'with a tube that reracks to a location that depends on the rerack of another tube that should be moved in the same request' do
        let(:target_plate) { create :plate_with_tagged_wells }
        let(:well1) { target_plate.wells[0] }
        let(:well2) { target_plate.wells[1] }
        let(:well3) { target_plate.wells[2] }
        subject { "/api/1/#{target_plate.uuid}/extraction_attributes" }
        let(:payload) do
          %{{
            "extraction_attribute":{
              "created_by": "#{user.name}",
              "attributes_update": [
                {
                  "uuid": "#{well1.uuid}",
                  "location": "B1"
                },
                {
                  "uuid": "#{well2.uuid}",
                  "location": "C1"
                }
              ]
            }
          }}
        end

        setup do
          @well1 = target_plate.wells.located_at('A1').first
          @well2 = target_plate.wells.located_at('B1').first
          @well3 = target_plate.wells.located_at('C1').first

          authorized_api_request :post, subject, payload

          [@well1, @well2, @well3].each(&:reload)

          @well4 = target_plate.wells.located_at('A1').first
          @well5 = target_plate.wells.located_at('B1').first
          @well6 = target_plate.wells.located_at('C1').first
        end

        it 'extracts from the rack the well that is not in any parent rack anymore' do
          expect(status).to eq(response_code)
          expect(@well3.parent).to eq(nil)
        end

        it 'performs reracks of wells' do
          expect(status).to eq(response_code)
          expect(@well5.samples).to eq(@well1.samples)
          expect(@well6.samples).to eq(@well2.samples)
        end

        context 'swapping of tubes' do
          let(:well1) { target_plate.wells.located_at('A1').first }
          let(:well2) { target_plate.wells.located_at('B1').first }
          let(:payload) do
            %{{
              "extraction_attribute":{
                "created_by": "#{user.name}",
                "attributes_update": [
                  {
                    "uuid": "#{well1.uuid}",
                    "location": "B1"
                  },
                  {
                    "uuid": "#{well2.uuid}",
                    "location": "A1"
                  }
                ]
              }
            }}
          end

          it 'swaps the tubes position' do
            authorized_api_request :post, subject, payload
            expect(status).to eq(response_code)

            [well1, well2].each(&:reload)
            well4 = target_plate.wells.located_at('A1').first
            well5 = target_plate.wells.located_at('B1').first

            expect(well1.samples).to eq(well5.samples)
            expect(well2.samples).to eq(well4.samples)
          end
        end
      end
    end
  end

  # Move into a helper as this expands
  def authorized_api_request(action, path, body)
    headers = {
      'HTTP_ACCEPT' => 'application/json'
    }
    headers['CONTENT_TYPE'] = 'application/json' unless body.nil?
    headers['HTTP_X_SEQUENCESCAPE_CLIENT_ID'] = authorised_app.key
    yield(headers) if block_given?
    send(action.downcase, path, body, headers)
  end
end
