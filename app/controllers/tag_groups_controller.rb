class TagGroupsController < ApplicationController
  before_filter :admin_login_required, :only => [:new, :edit, :create, :update]

  def index
    @tag_groups = TagGroup.find(:all)

    respond_to do |format|
      format.html
    end
  end

  def show
    @tag_group = TagGroup.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def new
    @number_of_tags = params[:number_of_tags]
    @tag_group = TagGroup.new

    respond_to do |format|
      format.html
    end
  end

  def edit
    @tag_group = TagGroup.find(params[:id])
  end

  def create
    @tag_group = TagGroup.new(params[:tag_group])
    @tags = @tag_group.create_tags(params[:tags])

    respond_to do |format|
      if @tag_group.save
        flash[:notice] = 'Tag Group was successfully created.'
        format.html { redirect_to(@tag_group) }
      else
        format.html { redirect_to(@tag_group) }
      end
    end
  end

  def update
    @tag_group = TagGroup.find(params[:id])

    respond_to do |format|
      if @tag_group.update_attributes(params[:tag_group])
        flash[:notice] = 'Tag Group was successfully updated.'
        format.html { redirect_to(@tag_group) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

end
