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

class ProjectMilestone < ActiveRecord::Base
  include ActionController::UrlWriter

  belongs_to :project

  belongs_to :company, :foreign_key => 'assigned_to_company_id'
  belongs_to :user,    :foreign_key => 'assigned_to_user_id'

  belongs_to :completed_by, :class_name => 'User', :foreign_key => 'completed_by_id'

  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
  belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'

  has_many :project_task_lists, :foreign_key => 'milestone_id', :order => "#{self.connection.quote_column_name 'order'} DESC", :dependent => :nullify do
    def public(reload=false)
      # Grab public comments only
      @public_task_lists = nil if reload
      @public_task_lists ||= all(:conditions => ['is_private = ?', false])
    end
  end

  has_many :project_messages, :foreign_key => 'milestone_id', :dependent => :nullify do
    def public(reload=false)
      # Grab public comments only
      @public_messages = nil if reload
      @public_messages ||= all(:conditions => ['is_private = ?', false])
    end
  end

  #has_many :tags, :as => 'rel_object', :dependent => :destroy

  before_validation_on_create  :process_params
  after_create   :process_create
  before_update  :process_update_params
  before_destroy :process_destroy

  def process_params
    write_attribute("completed_on", nil)

    if self.assigned_to_user_id.nil?
      write_attribute('assigned_to_user_id', 0)
    end
    if self.assigned_to_company_id.nil?
      write_attribute('assigned_to_company_id', 0)
    end
  end

  def process_create
    ApplicationLog::new_log(self, self.created_by, :add, self.is_private)
  end

  def process_update_params
    if self.assigned_to_user_id.nil?
      write_attribute('assigned_to_user_id', 0)
    end
    if self.assigned_to_company_id.nil?
      write_attribute('assigned_to_company_id', 0)
    end

    if @update_completed.nil?
      ApplicationLog::new_log(self, self.updated_by, :edit, self.is_private)
    else
      write_attribute('completed_on', @update_completed ? Time.now.utc : nil)
      self.completed_by = @update_completed_user
      ApplicationLog::new_log(self, @update_completed_user, @update_completed ? :close : :open, self.is_private)
    end
  end

  def process_destroy
    Tag.clear_by_object(self)
    ApplicationLog::new_log(self, self.updated_by, :delete, self.is_private)
  end

  def object_name
    self.name
  end

  def object_url
    url_for :only_path => true, :controller => 'milestone', :action => 'view', :id => self.id, :active_project => self.project_id
  end

  def tags
    Tag.list_by_object(self).join(',')
  end

  def tags_with_spaces
    Tag.list_by_object(self).join(' ')
  end

  def tags=(val)
    Tag.clear_by_object(self)
    Tag.set_to_object(self, val.split(',')) unless val.nil?
  end

  def assigned_to=(obj)
    self.company = obj.class == Company ? obj : nil
    self.user = obj.class == User ? obj : nil
  end

  def assigned_to
    return self.company if self.company
    return self.user    if self.user
    nil
  end

  def assigned_to_id=(val)
    # Set assigned_to accordingly
    if val.nil? or val == '0' or val == 'c0'
      self.assigned_to = nil
      return
    end

    begin
      self.assigned_to = val[0] == 99 ?
        Company.find(val[1...val.length]) :
        User.find(val)
    rescue ActiveRecord::RecordNotFound
      self.assigned_to = nil
    end
  end

  def assigned_to_id
    return "c#{self.company.id}" if self.company
    return self.user.id.to_s     if self.user
    '0'
  end

  def is_upcoming?
    self.due_date.to_date > Date.tomorrow
  end

  def is_late?
    self.due_date.to_date < Date.today
  end

  def is_today?
    self.due_date.to_date == Date.today
  end

  def is_completed?
    self.completed_on != nil
  end

  def days_left
    (self.due_date.to_date - Date.today).to_i
  end

  def days_late
    (Date.today - self.due_date.to_date).to_i
  end

  def last_edited_by_owner?
    self.created_by.member_of_owner? or (!self.updated_by.nil? and self.updated_by.member_of_owner?)
  end

  def send_comment_notifications(comment)
  end

  def set_completed(value, user=nil)
    @update_completed = value
    @update_completed_user = user
  end

  def self.priv_scope(include_private)
    if include_private
      yield
    else
      with_scope :find => { :conditions =>  ['is_private = ?', false] } do
        yield
      end
    end
  end

  # Core Permissions

  def self.can_be_created_by(user, project)
    project.is_active? and user.has_permission(project, :can_manage_milestones)
  end

  def can_be_edited_by(user)
    return false if (!project.is_active? or !user.member_of(project))
    user.is_admin or self.created_by.id == user.id
  end

  def can_be_deleted_by(user)
    project.is_active? and user.member_of(project) and user.is_admin
  end

  def can_be_seen_by(user)
    user.member_of(project) and !(self.is_private and !user.member_of_owner?)
  end

  # Specific Permissions

  def can_be_managed_by(user)
    project.is_active? and user.has_permission(project, :can_manage_milestones)
  end

  def status_can_be_changed_by(user)
    return true if can_be_edited_by(user)

    milestone_assigned_to = self.assigned_to
    (milestone_assigned_to == user) or (milestone_assigned_to == user.company)
  end

  def comment_can_be_added_by(user)
    project.is_active? and project.has_member(user) and !user.is_anonymous?
  end

  # Helpers

  def self.all_by_user(user)
    projects = user.active_projects
    project_ids = projects.collect{ |project| project.id }
    return [] if project_ids.empty?

    msg_conditions = user.member_of_owner? ?
      { :completed_on => nil, :project_id => project_ids } :
      { :completed_on => nil, :project_id => project_ids, :is_private => false }

    self.all(:conditions => msg_conditions)
  end
	
  def self.all_assigned_to(user, assignee, start_time=nil, end_time=nil, real_projects=nil, exclude_inactive=false)
    project_ids = (real_projects || user.active_projects).collect { |p| p.id }
    return [] if project_ids.empty?

    # Milestone not completed, visible, and part of project(s)?
    msg_conditions = {'project_milestones.completed_on' => nil, 'project_id' => project_ids}
    msg_conditions['is_private'] = false unless user.member_of_owner?

    # Exclude inactive projects?
    msg_joins = nil
    if exclude_inactive
      msg_conditions['projects.completed_on'] = nil
      msg_joins = 'INNER JOIN projects ON projects.id = project_milestones.project_id'
    end

    # Restrict by time
    unless start_time.nil?
      time_conditions = ['due_date >= ?', start_time]
    else
      time_conditions = nil
    end

    unless end_time.nil?
      if time_conditions.nil?
        time_conditions = ['due_date <= ?', end_time]
      else
        time_conditions[0] += ' AND due_date <= ?'
        time_conditions << end_time
      end
    end

    # Limit by assignee
    if assignee.class == User
      msg_conditions['assigned_to_user_id'] = assignee.id
    elsif assignee.class == Company
      msg_conditions['assigned_to_company_id'] = assignee.id
    end

    with_scope(:find => {:conditions => time_conditions}) do
      self.find(:all, :conditions => msg_conditions, :order => 'due_date ASC', :joins => msg_joins)
    end
  end

  def self.todays_by_user(user)
    from_date = Date.today
    to_date = Date.today + 1

    projects = user.active_projects
    project_ids = projects.collect{ |project| project.id}.join(',')
    return [] if project_ids.empty?

    msg_conditions = user.member_of_owner? ?
      ["completed_on IS NULL AND (due_date >= '#{from_date}' AND due_date < '#{to_date}') AND project_id IN (#{project_ids})"] :
      ["completed_on IS NULL AND (due_date >= '#{from_date}' AND due_date < '#{to_date}') AND project_id IN (#{project_ids}) AND is_private = ?", false]

    self.all(:conditions => msg_conditions)
  end

  def self.late_by_user(user)
    due_date = Date.today

    projects = user.active_projects

    project_ids = projects.collect{ |project| project.id }.join(',')

    return [] if project_ids.empty?

    msg_conditions = user.member_of_owner? ?
      ["due_date < '#{due_date}' AND completed_on IS NULL AND project_id IN (#{project_ids})"] :
      ["due_date < '#{due_date}' AND completed_on IS NULL AND project_id IN (#{project_ids}) AND is_private = ?", false]

    self.all(:conditions => msg_conditions)
  end

  # Accesibility

  attr_accessible :name, :description, :due_date, :assigned_to_id, :is_private

  # Validation

  validates_presence_of :name
  validates_each :is_private, :if => Proc.new { |obj| !obj.last_edited_by_owner? } do |record, attr, value|
    record.errors.add(attr, :not_allowed.l) if value == true
  end

  validates_each :assigned_to, :allow_nil => true do |record, attr, value|
    record.errors.add(attr, :not_part_of_project.l) if !value.nil? and !value.is_part_of(record.project)
  end
end
