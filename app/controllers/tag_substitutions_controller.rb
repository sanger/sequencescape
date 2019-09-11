# frozen_string_literal: true

#
# The TagSubstitutionsController provides a means of updating tags post
# library creation. The form is provided with an asset id (through the route)
# which helps populate the initial form, and allows new tags to be selected
#
# @author grl
#
class TagSubstitutionsController < ApplicationController
  # A list of suggested reasons for the drop down.
  SUGGESTED_REASONS = [
    'Incorrect tags supplied in manifest.',
    'Incorrect tags selected in Sequencescape.',
    'Samples switched at tag application.',
    'Incorrect tags applied by accident.',
    'Tag substituted intentionally, but unsupported by Sequencescape.'
  ].freeze

  before_action :prepare_form, only: :new

  def new
    @receptacle_id = params[:receptacle_id]
    @tag_substitution = TagSubstitution.new(template_asset: Receptacle.find(params[:receptacle_id]))
  end

  def create
    @receptacle_id = params[:receptacle_id]
    @tag_substitution = TagSubstitution.new(tag_substitution_params)

    if @tag_substitution.save
      redirect_to receptacle_path(params[:receptacle_id]), notice: 'Your substitution was performed.'
    else
      prepare_form
      flash.now[:error] = 'Your tag substitution could not be performed.'
      render action: :new
    end
  end

  private

  def prepare_form
    @suggested_reasons = SUGGESTED_REASONS
    @complete_tags = Tag.includes(:tag_group)
                        .pluck(Arel.sql('CONCAT(map_id, " - ", oligo)'), :id, 'tag_groups.name')
                        .index_by(&:second)
  end

  def tag_substitution_params
    params.require(:tag_substitution).permit(
      :reason, :ticket, :name, substitutions: %i[
        sample_id library_id original_tag_id substitute_tag_id original_tag2_id substitute_tag2_id
      ]
    ).merge(user: current_user)
  end
end
