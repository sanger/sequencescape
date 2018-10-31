module PrototypeReplacementHelper
  # def button_to_remote(*args); end

  # button_to_remote "Remove", {:url => remove_user_role_admin_user_path(:id => @user, :role => {:authorizable_id => role.authorizable_id, :authorizable_type => role.authorizable_type.downcase, :authorizable_name => role.name }), :update => "role_list"}, {:class=>'btn btn-danger'}
  # <%= form_tag [:grant_user_role_admin,@user], :remote => true, :data => {:success => "#role_list"}, :class => 'form-inline remote-form' do -%>
  def remote_button(label, url, data, html_options = {})
    form_tag url, remote: true, data: data, class: 'remote-form' do
      submit_tag(label, html_options)
    end
  end

  def tooltip(name = 'Help', opts = {}, &block)
    button = content_tag(:span, name, class: 'btn btn-info popover-trigger', 'data-content': capture(opts, &block),
                                      'data-toggle': 'popover', 'data-title': opts.fetch(:title, 'About this'))
    concat button
  end
end
