#==
# RailsCollab
# Copyright (C) 2007 - 2008 James S Urquhart
# Portions Copyright (C) René Scheibe
# Portions Copyright (C) Ariejan de Vroom
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

class MilestoneController < ApplicationController

  layout 'project_website'
  helper 'project_items'

  verify :method      => :post,
  		 :only        => [ :delete, :complete, :open ],
  		 :add_flash   => { :error => true, :message => :invalid_request.l },
         :redirect_to => { :controller => 'project' }

  before_filter :process_session
  before_filter :obtain_milestone, :except => [:index, :add]
  after_filter  :user_track,       :only   => [:index, :view]

  def index
    @time_now = Time.zone.now
    include_private = @logged_user.member_of_owner?
  	
    @late_milestones = @active_project.project_milestones.late(include_private)
    @upcoming_milestones = ProjectMilestone.all_assigned_to(@logged_user, nil, @time_now.utc.to_date, (@time_now.utc + 14.days).to_date, [@active_project])
    @completed_milestones = @active_project.project_milestones.completed(include_private)
    
    end_date = (@time_now + 14.days).to_date
    @calendar_milestones = @upcoming_milestones.group_by do |obj| 
      date = obj.due_date.to_date
      "#{date.month}-#{date.day}"
    end
    
    @content_for_sidebar = 'index_sidebar'
  end

  def view
    unless @milestone.can_be_seen_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'milestone'
      return
    end
  end

  def add
    @milestone = ProjectMilestone.new

    unless ProjectMilestone.can_be_created_by(@logged_user, @active_project)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'milestone'
      return
    end

    case request.method
      when :post
        milestone_attribs = params[:milestone]

        @milestone.attributes = milestone_attribs

        @milestone.created_by = @logged_user
        @milestone.project = @active_project

        if @milestone.save
          @milestone.tags = milestone_attribs[:tags]

          error_status(false, :success_added_milestone)
          redirect_back_or_default :controller => 'milestone'
        end
    end
  end

  def edit
    unless @milestone.can_be_edited_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'milestone'
      return
    end

    case request.method
      when :post
        milestone_attribs = params[:milestone]

        @milestone.attributes = milestone_attribs
        @milestone.updated_by = @logged_user
        @milestone.tags = milestone_attribs[:tags]

        if @milestone.save
          error_status(false, :success_edited_milestone)
          redirect_back_or_default :controller => 'milestone'
        end
    end
  end

  def delete
    unless @milestone.can_be_deleted_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'milestone'
      return
    end

    @milestone.updated_by = @logged_user
    @milestone.destroy

    error_status(false, :success_deleted_milestone)
    redirect_back_or_default :controller => 'milestone'
  end

  def complete
    unless @milestone.status_can_be_changed_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'milestone'
      return
    end

    if @milestone.is_completed?
      error_status(true, :milestone_already_completed)
      redirect_back_or_default :controller => 'milestone'
      return
    end

	@milestone.set_completed(true, @logged_user)
    error_status(true, :error_saving) unless @milestone.save
    redirect_back_or_default :controller => 'milestone', :action => 'view', :id => @milestone.id
  end

  def open
    unless @milestone.status_can_be_changed_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'milestone'
      return
    end

    unless @milestone.is_completed?
      error_status(true, :milestone_already_open)
      redirect_back_or_default :controller => 'milestone'
      return
    end

	@milestone.set_completed(false)
    error_status(true, :error_saving) unless @milestone.save
    redirect_back_or_default :controller => 'milestone', :action => 'view', :id => @milestone.id
  end

  private

  def obtain_milestone
    begin
      @milestone = @active_project.project_milestones.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_milestone)
      redirect_back_or_default :controller => 'milestone'
      return false
    end

    true
  end
end
