namespace :studies do
  desc 'Runs the annotation callbacks'
  task annotate: :environment do
    puts 'Annotating items'
    a = []
    Annotation.all.each do |annotation|
      annotation.send('external_callback')
      a << annotation
    end

    for annotation in a
      puts "#{annotation.annotated.id}: Annotated to Q20: #{annotation.q20_yield}: run #{annotation.identifier}, lane #{annotation.location}"
      annotation.event_notification
    end
  end
end
