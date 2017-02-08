# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
def open_barcode_stream
  user = 'read_only'
  password = 'read_only'
  connection = 'cas'
  open "|sqlplus -S #{user}/#{password}@#{connection}", 'r+' do |f|
    f.print <<-EOS
    SET PAGES 0
    SELECT id_person, email
    FROM PERSON
    WHERE iscurrent = 1
    ;
    EOS

    yield(f)
  end
end

def read_user_id
  user_barcode = {}
  open_barcode_stream do |f|
    while l = f.gets
      l.strip!
      break if /rows selected/i =~l
      break if /^$/ =~l
      raise Exception.new, "'#{l}' is not a valid id" unless /^\d+$/ =~l
      id = l.to_i
      user = f.gets.strip

      user_barcode[user] = id
      puts "#{user} => #{id}"

      f.gets # read a blamk lien as record separator
    end

    f.close
    user_barcode
  end
end

def update_user
  user_to_id = read_user_id
  puts "User number #{User.all.size}"
  User.all.each do |user|
    barcode_id = user_to_id[user.login]
    if barcode_id
      barcode = Barcode.barcode_to_human(Barcode.calculate_barcode('ID', barcode_id))
      if barcode != user.barcode
        puts "assigning new barcode '#{barcode_id}' to user '#{user.login}'"
        user.barcode = barcode
        user.save
      end
    end
  end
end

ActiveRecord::Base.transaction do
  update_user
end
