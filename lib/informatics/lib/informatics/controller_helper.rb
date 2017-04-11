
require File.dirname(__FILE__) + '/view/menu/item'
require File.dirname(__FILE__) + '/view/menu/list'
require File.dirname(__FILE__) + '/view/tabs/item'
require File.dirname(__FILE__) + '/view/tabs/list'

module ApplicationHelper
  include Informatics::Globals

  def add(type, link, options = nil)
    o = Informatics::Support::Options.collect(options)
    l = Informatics::Support::Options.collect(link)
    case type
      when :menu
        @menu = Informatics::View::Menu::List.new unless @menu
        @menu = add_link(@menu, l, o, options)
      when :back_menu
        @back_menu = Informatics::View::Menu::List.new unless @back_menu
        @back_menu.add_item text: l.first_key, link: l.first_value
      when :about # Replaces :title
        @about = link
      when :title # This option is deprecated in favour of :about as that is how it was getting used
        @about = link
      when :lab_option
        @lab_menu = add_link(@lab_menu, l, o, options)
      when :lab_manager_option
        @lab_manager_menu = add_link(@lab_manager_menu, l, o, options)
      when :admin_option
        @admin_menu = add_link(@admin_menu, l, o, options)
      when :manager_option
        @manager_menu = add_link(@manager_menu, l, o, options)
      when :banner
        @banner = link
      when :legend_option
        @legend = add_link(@legend, l, o, options)
      when :tab
        @tabs = Informatics::View::Tabs::List.new unless @tabs
        @tabs.add_item text: l.first_key, link: l.first_value
    end
  end

  def logger
    Rails.logger
  end

  private

  def add_link(menu, l, o, options)
    menu ||= Informatics::View::Menu::List.new
    if options.nil?
      menu.add_item text: l.first_key, link: l.first_value
    elsif o.key_is_present?(:confirm)
      if o.key_is_present?(:method)
        menu.add_item text: l.first_key, link: l.first_value, confirm: o.value_for(:confirm), method: o.value_for(:method)
      else
        menu.add_item text: l.first_key, link: l.first_value, confirm: o.value_for(:confirm)
      end
    end
    menu
  end
end
