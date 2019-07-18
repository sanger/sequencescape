# frozen_string_literal: true

['', 'Not suitable for alignment'].each do |name|
  ReferenceGenome.create!(name: name)
end
