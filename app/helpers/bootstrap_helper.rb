#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
module BootstrapHelper

  def panel(type=:default,options={},&block)
    title = options.delete(:title)
    options[:class] ||= String.new
    options[:class] << " panel panel-#{type}"
    content_tag(:div,options) do
      out = String.new.html_safe
      out << content_tag(:div,:class=>"panel-heading") do
        content_tag(:h3,title,:class=>"panel-title")
      end unless title.nil?
      out << content_tag(:div,:class=>"panel-body",&block)
    end
  end

  def bootstrapify(level)
    {
      'notice' => 'success','error' => 'danger',
      'pending' => 'muted', 'started'=> 'primary',
      'passed' => 'success', 'failed' => 'danger',
      'cancelled' => 'warning'
    }[level]||level
  end

  # <div class="alert alert-warning" role="alert">
  #  block_content
  # </div>
  def alert(type=:default,options={},&block)
    bs_type = bootstrapify(type.to_s)
    options[:class] ||= String.new
    options[:role] ||= 'alert'
    options[:class] << " alert alert-#{bs_type}"
    content_tag(:div,options,&block)
  end

  # Summary composits a panel with a table to deliver
  # a list of key-value pairs
  # <div class="col-md-6">
  #   <div class="panel panel-default">
  #     <div class="panel-heading"><h3 class="panel-title">Summary</h3></div>
  #     <table class='table table-summary'>
  #       <tr>
  #         <th>Array[0][0]</th>
  #         <td>Array[0][1]</td>
  #       </tr>
  #     </table>
  #   </div>
  # </div>
  def summary(type=:default,options={},&block)
    bs_type = bootstrapify(type.to_s)
    title = options.delete(:title)||'Summary'
    size = options.delete(:size)||'6'
    options[:class] ||= String.new
    options[:class] << " panel panel-#{bs_type}"
    content_tag(:div, :class=>"col-md-#{size}") do
      content_tag(:div,options) do
        content_tag(:div,:class=>"panel-heading") do
          content_tag(:h3,title,:class=>"panel-title")
        end <<
        content_tag(:table,:class=>"table table-summary") do
          String.new.html_safe.tap do |rows|
            yield.each do |key,value|
              rows << content_tag(:tr) do
                content_tag(:th,key) << content_tag(:td,value)
              end
            end
          end
        end
      end
    end
  end

  # <div class="page-header">
  #   <h1>Title <small>subtitle</small></h1>
  # </div>
  def page_title(title,subtitle=nil)
    content_tag(:div, :class=>"page-header") do
      content_tag(:h1) do
        core = escape_once(title.upcase).html_safe
        core << " " << content_tag(:small,subtitle) if subtitle.present?
        core
      end
    end
  end

  def pagination(collection)
    will_paginate collection, renderer: BootstrapPagination::Rails, previous_label: "&laquo;", next_label: "&raquo;"
  end

  #<div class="col-md-size form-group"></div>
  def form_group(size=12,&block)
    content_tag(:div,:class=>"form-group col-md-#{size}",&block)
  end

  def bs_column(size=6,screen='md',&block)
    content_tag(:div,:class=>"col-#{screen}-#{size}",&block)
  end

  # def progress_bar(percent = 100, hidden=true, identifier = "loading")
  #   display = hidden ? "display:none" : nil
  #   content_tag(:div, :class=>'progress', :style => display,) do
  #     content_tag("div", :id => identifier, :class => "progress-bar progress-bar-striped active", :role => 'progressbar') do
  #       content_tag(:span,'Loading...',:class=>'sr-only')
  #     end
  #   end
  # end


end
