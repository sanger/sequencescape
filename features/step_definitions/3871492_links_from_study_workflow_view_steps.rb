Given /^study "([^"]+)" has a registered sample "([^"]+)"$/ do |study_name,sample_name|
  study  = Study.first(:conditions => { :name => study_name }) or raise "No study defined with name '#{ study_name }'"
  sample = study.samples.create!(:name => sample_name)

  Factory::submission(
    :study => study,
    :assets => [ SampleTube.create!.tap { |sample_tube| sample_tube.aliquots.create!(:sample => sample) } ],
    :workflow => @current_user.workflow,
    :state => 'ready'
  )
end

Given /^study "([^"]+)" has made the following "([^"]+)" requests:$/ do |study_name,request_type,table|
  study        = Study.first(:conditions => { :name => study_name }) or raise "No study defined with name '#{ study_name }'"
  request_type = RequestType.first(:conditions => { :name => request_type }) or raise "No request type defined with name '#{ request_type }'"

  table.hashes.each do |row|
    state, asset_name, sample_name = row['state'], row['asset'], row['sample']
    asset  = Asset.first(:conditions => { :name => asset_name }) or raise "No asset defined with name '#{ asset_name }'"
    sample = Sample.first(:conditions => { :name => sample_name }) or raise "No sample defined with name '#{ sample_name }'"

    if asset.respond_to?(:aliquots)
      asset.aliquots.each do |aliquot|
        aliquot.update_attributes!(:study_id => study.id)
      end
    end

    count = (row['count'] == 'none') ? 0 : row['count'].to_i
    if count == 0
      requests = study.requests.for_asset_id(asset.id).for_state(state)
      requests.select { |r| r.samples.include?(sample)}.map(&:destroy) if requests.present?
    else
      count.to_i.times do |index|
        Factory(
          :request,
          :request_type => request_type,
          :user => @current_user, :workflow => @current_user.workflow,
          :study => study, :asset => asset, :state => state
        )
      end
    end
  end
end

When /^I activate the "([^"]+)" tab$/ do |tab_name|
  When %Q{I follow "#{tab_name}"}
end

Then /^the (pending|started|passed|failed|cancelled) requests for "([^"]+)" should not be a link$/ do |status,asset_name|
  assert_equal false, page.has_css?("a[title='#{ asset_name } #{ status }']"), "Link '#{asset_name} #{status}' exists"
end

When /^I view the (pending|started|passed|failed|cancelled) requests for "([^"]+)"$/ do |status,asset_name|
  When %Q{I follow "#{ asset_name } #{ status }"}
end
