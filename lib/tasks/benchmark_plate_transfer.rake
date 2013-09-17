namespace :benchmark do
  task :plate_transfer => :environment do

    $stdout.puts "Preparing"
    stock = Purpose.find_by_name('Shear').create!
    sample = Sample.find_or_create_by_name('test_sample')
    stock.wells.each {|w| w.aliquots.create!(:sample=>sample, :study_id=>Study.find_or_create_by_name('test_study').id)}
    user = User.find_or_create_by_login('test_user')
    targets = []

    45.times do
      $stdout.print '.'
      targets << Purpose.find_by_name('Post Shear').create!
    end
    puts ''

    all_wells = Hash[('A'..'H').map{|r| (1..12).map {|c| "#{r}#{c}"}}.flatten.map {|w| [w,w]}]

    $stdout.puts "Warming up..."
    15.times do
      Transfer::BetweenPlates.create!(:source=>stock,:destination=>targets.pop, :transfers=>all_wells.clone, :user=>user)
      print '.'
    end
    puts ''

    start = Time.now
    $stdout.puts "Starting #{start}"
    30.times do
      Transfer::BetweenPlates.create!(:source=>stock,:destination=>targets.pop,:transfers=>all_wells.clone, :user=>user)
      $stdout.print '.'
    end
    $stdout.puts
    $stdout.puts "Took #{Time.now - start}"
  end
end
