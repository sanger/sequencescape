# Setup Default users, use password generic for compatability with cucumber

ngs = Submission::Workflow.find_by_name('Next-gen sequencing')
raise Exception, "Can't find workflow 'Next-gen sequencing'" if ngs==nil 
array = Submission::Workflow.find_by_name('Microarray genotyping')
raise Exception, "Can't find workflow 'Microarray genotyping'" if array==nil 

User.create!(:login=>'admin',       :password=>'generic', :workflow_id=>ngs, :first_name=>'admin',  :last_name=>'admin',    :email=>'admin@example.com').is_administrator

User.create!(:login=>'ngsmanager',  :password=>'generic', :workflow_id=>ngs, :first_name=>'NGS',    :last_name=>'Manager',  :email=>'ngsmanager@example.com').tap do |u|
  u.roles.create!(:name=>'manager')
end  
User.create!(:login=>'microarraymanager', :password=>'generic', :workflow_id=>array, :first_name=>'Microarray', :last_name=>'Manager', :email=>'microarraymanager@example.com').tap do |u|
  u.roles.create!(:name=>'manager')
end

User.create!(:login=>'owner', :password=>'generic', :first_name=>'owner', :last_name=>'owner', :email=>'owner@example.com').tap do |u|
  u.roles.create!(:name=>'owner')
end

User.create!(:login=>'ngsadmin', :password=>'generic', :workflow_id=>ngs, :first_name=>'NGS', :last_name=>'Admin', :email=>'ngsadminr@example.com').is_administrator
User.create!(:login=>'microarrayadmin', :password=>'generic', :workflow_id=>array, :first_name=>'Microarray', :last_name=>'Admin', :email=>'microarrayadmin@example.com').is_administrator
