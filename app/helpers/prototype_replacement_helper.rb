#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
module PrototypeReplacementHelper
  # def button_to_remote(*args); end

  # button_to_remote "Remove", {:url => remove_user_role_admin_user_path(:id => @user, :role => {:authorizable_id => role.authorizable_id, :authorizable_type => role.authorizable_type.downcase, :authorizable_name => role.name }), :update => "role_list"}, {:class=>'btn btn-danger'}
  # <%= form_tag [:grant_user_role_admin,@user], :remote => true, :data => {:success => "#role_list"}, :class => 'form-inline remote-form' do -%>
  def remote_button(label,url,data,html_options={})
    form_tag url, :remote => true, :data => data, :class => 'remote-form' do
      submit_tag(label,html_options)
    end
  end


  def tooltip(name=nil, opts={}, &proc)
    name ||= image_tag('/images/widgets/tooltip_image.gif', :border => 0, :'data-content' => tooltip_content(opts,&proc),
     :'data-toggle' => 'popover', :'data-title'=> 'About this')
    result = name

    if block_given?
      concat result.html_safe
      return nil
    else
      return result.html_safe
    end
  end

end
