# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class ReferenceGenomesController < ApplicationController
  # WARNING! This filter bypasses security mechanisms in rails 4 and mimics rails 2 behviour.
  # It should be removed wherever possible and the correct Strong  Parameter options applied in its place.
  before_action :evil_parameter_hack!
  before_action :admin_login_required, only: [:new, :create, :edit, :update, :destroy]

  def index
    @reference_genomes = ReferenceGenome.alphabetical
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @reference_genomes }
    end
  end

  # GET /reference_genomes/1
  # GET /reference_genomes/1.xml
  def show
    @reference_genome = ReferenceGenome.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @reference_genome }
    end
  end

  # GET /reference_genomes/new
  # GET /reference_genomes/new.xml
  def new
    @reference_genome = ReferenceGenome.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @reference_genome }
    end
  end

  # GET /reference_genomes/1/edit
  def edit
    @reference_genome = ReferenceGenome.find(params[:id])
  end

  # POST /reference_genomes
  # POST /reference_genomes.xml
  def create
    @reference_genome = ReferenceGenome.new(params[:reference_genome])

    respond_to do |format|
      if @reference_genome.save
        format.html { redirect_to(@reference_genome, notice: 'Reference genome was successfully created.') }
        format.xml  { render xml: @reference_genome, status: :created, location: @reference_genome }
      else
        format.html { render action: 'new' }
        format.xml  { render xml: @reference_genome.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /reference_genomes/1
  # PUT /reference_genomes/1.xml
  def update
    @reference_genome = ReferenceGenome.find(params[:id])

    respond_to do |format|
      if @reference_genome.update_attributes(params[:reference_genome])
        format.html { redirect_to(@reference_genome, notice: 'Reference genome was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml  { render xml: @reference_genome.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /reference_genomes/1
  # DELETE /reference_genomes/1.xml
  def destroy
    @reference_genome = ReferenceGenome.find(params[:id])
    @reference_genome.destroy

    respond_to do |format|
      format.html { redirect_to(reference_genomes_url) }
      format.xml  { head :ok }
    end
  end
end
