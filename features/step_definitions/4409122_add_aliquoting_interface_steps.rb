Given /^sample "([^\"]+)" is in a sample tube named "([^\"]+)" with a two dimensional barcode "([^\"]+)"$/ do |sample_name,sample_tube_name, two_dimensional_barcode|
  sample = Sample.find_by_name(sample_name) or raise StandardError, "Could not find a sample named '#{ sample_name }'"
  Factory(:sample_tube, :name => sample_tube_name, :sample => sample, :two_dimensional_barcode => two_dimensional_barcode) or raise StandardError, "Could not create sample tube named '#{ sample_tube_name }'"
end

Given /^a sample tube named "([^\"]*)" exists with a two dimensional barcode "([^\"]*)"$/ do |sample_tube_name, two_dimensional_barcode|
  Factory(:sample_tube, :name => sample_tube_name, :two_dimensional_barcode => two_dimensional_barcode) or raise StandardError, "Could not create sample tube named '#{ sample_tube_name }'"
end

Given /^study "([^\"]+)" has the following registered samples in sample tubes( with a request)?:$/ do |study_name, with_a_request, table|
  study = Study.find_by_name(study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  table.hashes.each do |details|
    sample_tube_name = details['sample tube']
    sample      = study.samples.create!(:name => details['sample'])
    sample_tube = Factory(:empty_sample_tube, :name => sample_tube_name).tap { |tube| tube.aliquots.create!(:sample => sample) }

    Factory::submission(
      :study => study,
      :assets => [ sample_tube ],
      :workflow => @current_user.workflow,
      :state => 'ready'
    )

    And %Q{the asset "#{sample_tube_name}" belongs to study "#{study_name}"} if with_a_request

  end
end
