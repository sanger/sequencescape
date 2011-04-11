Given /^sample "([^\"]+)" is in a sample tube named "([^\"]+)" with a two dimensional barcode "([^\"]+)"$/ do |sample_name,sample_tube_name, two_dimensional_barcode|
  sample = Sample.find_by_name(sample_name) or raise StandardError, "Could not find a sample named '#{ sample_name }'"
  Factory(:sample_tube, :name => sample_tube_name, :material => sample, :two_dimensional_barcode => two_dimensional_barcode) or raise StandardError, "Could not create sample tube named '#{ sample_tube_name }'"
end

Given /^a sample tube named "([^\"]*)" exists with a two dimensional barcode "([^\"]*)"$/ do |sample_tube_name, two_dimensional_barcode|
  Factory(:sample_tube, :name => sample_tube_name, :two_dimensional_barcode => two_dimensional_barcode) or raise StandardError, "Could not create sample tube named '#{ sample_tube_name }'"
end

Given /^study "([^\"]+)" has the following registered samples in sample tubes:$/ do |study_name, table|
  study = Study.find_by_name(study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  table.hashes.each do |details|
    sample_tube_name = details['sample tube']
    sample      = study.samples.create!(:name => details['sample'])
    sample_tube = Factory(:sample_tube, :name => sample_tube_name, :material => sample)

    Factory(
      :submission,
      :study => study,
      :assets => [ sample_tube ],
      :workflow => @current_user.workflow,
      :state => 'ready'
    )
    And %Q{the asset "#{sample_tube_name}" belongs to study "#{study_name}"}

  end
end
