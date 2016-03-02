#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2016 Genome Research Ltd.

# Bootstrapification helpers are used to convert states and other internal
# strings to bootstrap equivalents
module BootstrapificationHelper

  def bootstrapify(level)
    {
      'notice' => 'success','error' => 'danger',
      'pending' => 'muted', 'started'=> 'primary',
      'passed' => 'success', 'failed' => 'danger',
      'cancelled' => 'warning'
    }[level]||level
  end


  def bootstrapify_request_state(state)
    {
      'completed' => 'info',
      'discarded' => 'default',
      'cancelled' => 'default',
      'failed' => 'danger',
      'pending' => 'warning',
      'passed' => 'success',
      'started' => 'primary'
    }[state]||'default'
  end

  def bootstrapify_batch_state(state)
    {
      'completed' => 'info',
      'discarded' => 'default',
      'failed' => 'danger',
      'pending' => 'warning',
      'released' => 'success',
      'started' => 'primary'
    }[state]||'default'
  end


  def bootstrapify_study_state(state)
    {
      'pending' => 'warning',
      'active'  => 'success',
      'inactive' => 'danger'
    }[state.downcase]||'default'
  end

  def bootstrapify_submission_state(state)
    {
      'building' => 'info',
      'cancelled' => 'default',
      'failed' => 'danger',
      'pending' => 'warning',
      'processing' => 'primary',
      'ready' => 'success'
    }[state]||'default'
  end


end
