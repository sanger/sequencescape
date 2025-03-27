# frozen_string_literal: true
require_relative 'view/menu/item'
require_relative 'view/menu/list'
require_relative 'view/tabs/item'
require_relative 'view/tabs/list'
require_relative 'globals'

module ControllerHelper
  # Extends the application helper with methods to add menu items, tabs, and legends and logging

  include Informatics::Globals

  # rubocop:todo Metrics/MethodLength, Metrics/AbcSize
  def add(type, link, options = nil) # rubocop:todo Metrics/CyclomaticComplexity
    o = Informatics::Support::Options.collect(options)
    l = Informatics::Support::Options.collect(link)
    case type
    when :menu
      @menu ||= Informatics::View::Menu::List.new
      @menu = add_link(@menu, l, o, options)
    when :back_menu
      @back_menu ||= Informatics::View::Menu::List.new
      @back_menu.add_item text: l.first_key, link: l.first_value
    when :about, :title
      # Replaces :title
      @about = link
    when :legend_option
      @legend = add_link(@legend, l, o, options)
    when :tab
      @tabs = Informatics::View::Tabs::List.new unless @tabs
      @tabs.add_item text: l.first_key, link: l.first_value
    end
  end

  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  delegate :logger, to: :Rails

  private

  def add_link(menu, l, o, options) # rubocop:todo Metrics/MethodLength
    menu ||= Informatics::View::Menu::List.new
    if options.nil?
      menu.add_item text: l.first_key, link: l.first_value
    elsif o.key_is_present?(:confirm)
      if o.key_is_present?(:method)
        menu.add_item text: l.first_key,
                      link: l.first_value,
                      confirm: o.value_for(:confirm),
                      method: o.value_for(:method)
      else
        menu.add_item text: l.first_key, link: l.first_value, confirm: o.value_for(:confirm)
      end
    end
    menu
  end
end
