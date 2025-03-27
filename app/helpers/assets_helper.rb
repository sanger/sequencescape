# frozen_string_literal: true
module AssetsHelper
  def well_identifier(plate_layout, row, column)
    plate_layout.cell_name_for_well_at(row, column)
  end

  def well_information(plate_layout, row, column) # rubocop:todo Metrics/MethodLength
    well = plate_layout.well_at(row, column)
    if plate_layout.empty_well_at?(row, column)
      ['Empty', '', '']
    elsif plate_layout.good_well_at?(row, column)
      ["Request ID: #{well[:request].id}", "Asset: #{well[:asset].name}", "Barcode: #{well[:asset].barcode}"]
    elsif plate_layout.bad_well_at?(row, column)
      ['Error', well[:error].to_s, '']
    else
      raise StandardError,
            "Unknown well status ((#{plate_layout.location_for_well_at(row, column)}) = #{
              plate_layout.well_at(row, column).inspect
            })"
    end
  end

  def well_color(plate_layout, row, column)
    if plate_layout.empty_well_at?(row, column)
      'empty_cell'
    elsif plate_layout.good_well_at?(row, column)
      'good_cell'
    else
      'bad_cell'
    end
  end

  # Returns an appropriate path given the current parameters
  def new_request_receptacle_path_in_context(asset)
    path_options = asset.is_a?(Receptacle) ? { id: asset.id } : asset.receptacle.id
    path_options[:study_id] = params[:study_id] if params.key?(:study_id)
    new_request_receptacle_path(path_options)
  end

  # Given the core name of an instance variable or ID parameter this method yields the name of the ID
  # parameter along with its current value, based either on the instance variable ID value or the
  # ID parameter.  For instance, if the 'name' is 'foo' then either the '@foo.id' value will be yielded,
  # or the 'params[:foo_id]' value if @foo is nil.
  def instance_variable_or_id_param(name, &)
    field_name, value = :"#{name}_id", instance_variable_get(:"@#{name}")
    value_id = value.nil? ? params[field_name] : value.id
    concat(capture(field_name, value_id, &))
  end

  # Returns a select tag that has it's options ordered by name (assumes present of sorted_by_name function)
  # and disabled if a value has been pre-selected.
  def select_field_sorted_by_name(field, select_options_source, selected, can_edit, options = {})
    disabled = selected.present? && !can_edit

    tag.div(class: 'col-md-5') do
      select_tag(
        field,
        options_for_select(select_options_source.sorted_by_name.pluck(:name, :id), selected.try(:to_i)),
        options.merge(disabled: disabled, class: 'form-control select2')
      )
    end
  end

  # Returns true if the current user can request additional sequencing on the given asset, otherwise false
  def current_user_can_request_additional_sequencing_on?(asset)
    asset.sequenceable? && can?(:create_additional, Request)
  end

  # Returns true if the current user can request an additional library on the asset, otherwise false
  def current_user_can_request_additional_library_on?(asset)
    asset.is_a?(SampleTube) && can?(:create_additional, Request)
  end

  def current_user_can_make_additional_requests_on?(_asset, study)
    return false if study.blank? # Study must be specified ...

    can?(:create_additional, Request)
  end

  def current_user_studies
    Study.accessible_by(current_ability, :request_additional_with)
  end

  def labware_types
    ['All', *Labware.descendants.map(&:name)]
  end

  def labware_types_for_select
    labware_types.map { |at| [at.underscore.humanize, at] }
  end
end
