#==
# RailsCollab
# Copyright (C) 2007 - 2008 James S Urquhart
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

module DashboardHelper
  def current_tab
    case action_name
      when 'index', 'search' then :overview
      else action_name.to_sym
    end
  end

  def current_crumb
    case action_name
      when 'index' then :overview
      when 'search' then :search_results
      else super
    end
  end

  def additional_stylesheets
    case action_name
      when 'index' then ['project/project_log', 'application_logs']
      when 'milestones', 'my_tasks' then ['dashboard/my_tasks']
      when 'search' then ['project/search_results']
    end
  end

  def new_account_steps(user)
    [{:title   => :new_account_step1.l,
	  :content => :new_account_step1_info.l_with_args(:url => '/company/edit'),
	  :del     => Company.owner.updated?},

      {:title   => :new_account_step2.l,
	   :content => :new_account_step1_info.l_with_args(:url => "/user/add?company_id=#{user.company.id}"),
	   :del     => (Company.owner.users.length > 1)},

      {:title   => :new_account_step3.l,
	   :content => :new_account_step3_info.l_with_args(:url => '/company/add_client'),
	   :del     => (Company.owner.clients.length > 0)},

      {:title   => :new_account_step4.l,
	   :content => :new_account_step4_info.l_with_args(:url => '/project/add'),
	   :del     => (Company.owner.projects.length > 0)}]
  end
end
