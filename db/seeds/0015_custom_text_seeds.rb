# Adds CustomText instances to be used by Sequencescape...

unless Rails.env.test?
  CustomText.create!(
    identifier: 'app_info_box',
    differential: 1,
    content_type: 'text/html'
  )
end
