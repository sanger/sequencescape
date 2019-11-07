# @deprecated Part of the old Illumina-B Lims pipelines
# QC Plate purpose which delegates its state back up to its parent. Used by:
#
# - Post Shear QC
#
# @todo #2396 Remove this class. This will require:
#       - Update any purposes using this class to use PlatePurpose instead
#       - Update:
#           app/models/illumina_htp/plate_purposes.rb
#         By either replacing with PlatePurpose, or removing the factories entirely
class IlluminaHtp::PostShearQcPlatePurpose < PlatePurpose
  alias_method(:default_transition_to, :transition_to)

  def transition_to(plate, state, user, contents = nil, customer_accepts_responsibility = false)
    nudge_parent_plate(plate, state, user, contents)
    default_transition_to(plate, state, user, contents, customer_accepts_responsibility)
  end

  def nudge_parent_plate(plate, state, contents)
    case state
    when 'started' then plate.parent.transition_to('started', user, contents)
    when 'passed' then plate.parent.transition_to('passed', user, contents)
    end
  end
  private :nudge_parent_plate
end
