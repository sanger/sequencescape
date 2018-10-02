unless Rails.env.test?
  ['', 'Not suitable for alignment'].each do |name|
    ReferenceGenome.create!(name: name)
  end
end
