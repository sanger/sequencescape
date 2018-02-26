# frozen_string_literal: true

# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2018 Genome Research Ltd.

require 'rails_helper'

RSpec.describe LocationReport, type: :routing do
  # test routes go where they should
  context 'checking routing to location reports' do
    it 'routes /location_reports to location_reports#index' do
      expect(get: '/location_reports').to route_to(
        controller: 'location_reports',
        action: 'index'
      )
    end

    it 'routes /location_reports/1 to location_reports#show' do
      expect(get: '/location_reports/1').to route_to(
        controller: 'location_reports',
        action: 'show',
        id: '1'
      )
    end

    it 'routes /location_reports to location_reports#create' do
      expect(post: '/location_reports').to route_to(
        controller: 'location_reports',
        action: 'create'
      )
    end

    # test routes that should NOT be possible
    it 'does not route /location_reports/new to location_reports#new' do
      expect(get: '/location_reports/new').not_to be_routable
    end

    it 'does not route /location_reports/1/edit to location_reports#edit' do
      expect(get: '/location_reports/1/edit').not_to be_routable
    end

    it 'does not route /location_reports/1 to location_reports#update' do
      expect(put: '/location_reports/1').not_to be_routable
    end

    it 'does not route /location_reports/1 to location_reports#destroy' do
      expect(delete: '/location_reports/1').not_to be_routable
    end
  end
end
