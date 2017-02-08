# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015,2016 Genome Research Ltd.

module AssetsHelper
  def well_identifier(plate_layout, row, column)
    plate_layout.cell_name_for_well_at(row, column)
  end

  def well_information(plate_layout, row, column)
    well = plate_layout.well_at(row, column)
    if plate_layout.empty_well_at?(row, column)
      ['Empty', '', '']
    elsif plate_layout.good_well_at?(row, column)
      ["Request ID: #{well[:request].id}", "Asset: #{well[:asset].name}", "Barcode: #{well[:asset].barcode}"]
    elsif plate_layout.bad_well_at?(row, column)
      ['Error', (well[:error]).to_s, '']
    else
      raise StandardError, "Unknown well status ((#{plate_layout.location_for_well_at(row, column)}) = #{plate_layout.well_at(row, column).inspect})"
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
  def new_request_asset_path_in_context(asset)
    path_options = {}
    path_options[:study_id] = params[:study_id] if params.key?(:study_id)
    new_request_asset_path(path_options.merge(id: asset.id))
  end

  # Given the core name of an instance variable or ID parameter this method yields the name of the ID
  # parameter along with its current value, based either on the instance variable ID value or the
  # ID parameter.  For instance, if the 'name' is 'foo' then either the '@foo.id' value will be yielded,
  # or the 'params[:foo_id]' value if @foo is nil.
  def instance_variable_or_id_param(name, &block)
    field_name, value = :"#{name}_id", instance_variable_get(:"@#{name}")
    value_id          = value.nil? ? params[field_name] : value.id
    concat(capture(field_name, value_id, &block))
  end

  # Returns a select tag that has it's options ordered by name (assumes present of sorted_by_name function)
  # and disabled if a value has been pre-selected.
  def select_field_sorted_by_name(field, select_options_source, selected, options = {})
    content_tag(:div, class: 'col-md-5') do
      select_tag(
        field,
        options_for_select(select_options_source.sorted_by_name.map { |x| [x.name, x.id] }, selected.try(:to_i)),
        options.merge(disabled: (selected.present? and not current_user.is_administrator?), class: 'form-control select2')
      )
    end
  end

  # Returns true if the current user can request additional sequencing on the given asset, otherwise false
  def current_user_can_request_additional_sequencing_on?(asset)
    return false unless asset.is_sequenceable?                      # Asset must be sequenceable ...
    return true if current_user.is_administrator?                   # ... user could be an administrator ...
    return true if current_user.is_manager?
    # asset.studies.any? { |study| current_user.is_manager?(study) }  # ... or a manager of any study related to the asset
  end

  # Returns true if the current user can request an additional library on the asset, otherwise false
  def current_user_can_request_additional_library_on?(asset)
    asset.is_a?(SampleTube) and current_user.is_administrator?
  end

  def current_user_can_make_additional_requests_on?(_asset, study)
    return false unless study.present?              # Study must be specified ...
    return true if current_user.is_administrator?   # ... user could be an administrator ...
    current_user.is_manager?(study)                 # ... or the manager of the specified study
  end

  def current_user_studies_from(_asset)
    return Study if current_user.is_administrator?

    # Bit of a hack in that we want to provide the same interface as would be seen if this were an
    # ActiveRecord model rather than an array.
    Study.all.select { |study| current_user.is_manager?(study) }.tap do |results|
      def results.sorted_by_name
        sort_by(&:name)
      end
    end
  end

  def asset_types
    ['All', *Aliquot::Receptacle.descendants.map(&:name)]
  end

  def asset_types_for_select
    asset_types.map { |at| [at.underscore.humanize, at] }
  end
end
