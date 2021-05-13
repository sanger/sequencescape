# rubocop:todo Metrics/ModuleLength
module BootstrapHelper # rubocop:todo Style/Documentation
  def panel(type = :default, options = {}, &block)
    bs_custom_panel(type, :div, { class: 'card-body' }, options, &block)
  end

  def list_panel(type = :default, options = {}, &block)
    bs_custom_panel(type, :ul, { class: 'list-group list-group-flush' }, options, &block)
  end

  def link_panel(type = :default, options = {}, &block)
    bs_custom_panel(type, :div, { class: 'link-panel' }, options, &block)
  end

  def panel_no_body(type = :default, options = {}, &block)
    bs_custom_panel(type, :div, {}, options, &block)
  end

  def bs_custom_panel(type, body_type, body_options, options, &block)
    title = options.delete(:title)
    options[:class] ||= []
    options[:class] << " ss-card card-style-#{type}"
    tag.div(options) do
      concat tag.h3(title, class: 'card-header-custom') unless title.nil?
      concat content_tag(body_type, body_options, &block)
    end
  end

  # <div class="alert alert-warning" role="alert">
  #  block_content
  # </div>
  def alert(type = :default, options = {}, &block)
    options[:class] ||= []
    options[:role] ||= 'alert'
    options[:class] << " alert alert-#{type}"
    tag.div(options, &block)
  end

  # Summary composites a panel with a table to deliver
  # a list of key-value pairs
  #   <div class="card card-default">
  #     <h3 class="card-header">Summary</h3>
  #     <table class='table table-summary'>
  #       <tr>
  #         <th>Array[0][0]</th>
  #         <td>Array[0][1]</td>
  #       </tr>
  #     </table>
  #   </div>
  def summary(type = :default, options = {}) # rubocop:todo Metrics/MethodLength
    options[:title] ||= 'Summary'
    bs_custom_panel(type, :table, { class: 'table table-summary' }, options) do
      yield.each do |key, value|
        concat(
          tag.tr do
            concat tag.th(key)
            concat tag.td(value)
          end
        )
      end
    end
  end

  # <div class="page-header">
  #   <h1>Title <small>subtitle</small></h1>
  # </div>
  # rubocop:todo Metrics/MethodLength
  def page_title(title, subtitle = nil, titlecase: true, badges: []) # rubocop:todo Metrics/AbcSize
    tag.div(class: 'page-header') do
      title_class = title.length > 25 ? 'title-long' : 'title-short'
      tag.h1(class: title_class) do
        if titlecase
          concat title.titleize
        else
          concat title
        end
        concat ' '
        concat tag.span(subtitle, class: 'subtitle') if subtitle.present?
        badges.each do |badge_text|
          concat ' '
          concat badge(badge_text, type: 'title-badge')
        end
      end
    end
  end

  # rubocop:enable Metrics/MethodLength

  def pagination(collection)
    will_paginate collection, renderer: BootstrapPagination::Rails, previous_label: '&laquo;', next_label: '&raquo;'
  end

  # <div class="col-md-size form-group sqs-form"></div>
  def form_group(&block)
    tag.div(class: 'form-group row sqs-form', &block)
  end

  def bs_column(size = 6, screen = 'md', &block)
    tag.div(class: "col-#{screen}-#{size}", &block)
  end

  def progress_bar(count) # rubocop:todo Metrics/MethodLength
    css_class =
      if count < 25
        'bg-danger'
      elsif count > 99
        'bg-success'
      else
        'bg-warning'
      end
    tag.span(count, style: 'display:none') << tag.div(class: 'progress') do
      tag.div(
        "#{count}%",
        class: ['progress-bar', 'progress-bar-striped', css_class],
        role: 'progressbar',
        style: "width: #{count}%;"
      )
    end
  end

  # <div class="progress">
  #   <div class="progress-bar progress-bar-striped active" role="progressbar" aria-valuenow="45" aria-valuemin="0" aria-valuemax="100" style="width: 45%">
  #     <span class="sr-only">45% Complete</span>
  #   </div>
  # </div>
  def loading_bar(id = 'update_loader', show: false, text: 'Loading')
    tag.div(class: 'loading-bar-placeholder') do
      tag.div(id: id, class: 'loading-bar-container', style: show ? '' : 'display: none;') do
        tag.div(text, class: 'loading-bar', role: 'progressbar')
      end
    end
  end

  def render_section(form, field_name, sections, field)
    label =
      form.label(field_name, sections.label, sections.label_options) <<
        tag.span(sections.edit_info, class: 'property_edit_info')
    help = sections.help
    form_collection(label, field, help)
  end

  def render_radio_section(_form, _field_name, sections, field)
    label =
      tag.label(sections.label, sections.label_options) << tag.span(sections.edit_info, class: 'property_edit_info')
    help = sections.help
    tag.legend(sections.label, class: 'sr-only') << form_collection(label, field, help)
  end

  def form_collection(label, field, help = nil)
    form_group { bs_column(2, 'md') { label } << bs_column(10, 'md') { field << help_text { raw(help) } } }
  end

  def bs_select(*args)
    hashes = args[-2, 2].count { |arg| arg.respond_to?(:keys) }
    (2 - hashes).times { args << {} }
    args.last[:class] ||= ''
    args.last[:class] << ' custom-select'
    select(*args)
  end
end
# rubocop:enable Metrics/ModuleLength
