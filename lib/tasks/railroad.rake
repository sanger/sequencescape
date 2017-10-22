namespace :railroad do
  namespace :diagram do
    task :models do
      sh "railroad -j -i -l -m --hide-types -M -e #{Dir.glob("app/models/cas/*.rb").join(",")},#{Dir.glob("app/models/snp/*.rb").join(",")},app/models/user.rb,app/models/role.rb,app/models/asset.rb > doc/models.dot"
      # cat doc/new.svg| perl -pe 's/start(.*)font-size:14/start$1font-size:11/g' | perl -pe 's/middle(.*)font-size:14/middle$1font-size:16/g' >| doc/test.svg
    end

    task :controllers do
      sh "railroad -i -l -C | neato -Tsvg | sed 's/font-size:14.00/font-size:11.00/g' > doc/controllers.svg"
    end
  end

  task diagrams: %w(diagram:models diagram:controllers)
end
