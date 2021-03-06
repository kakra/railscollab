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

module UserHelper
  def page_title
    case action_name
      when 'card' then :user_card.l_with_args(:user => @user.display_name)
      else super
    end
  end

  def administration_tabbed_navigation
    super if @logged_user.company.is_owner?
  end

  def current_tab
    :people
  end

  def administration_crumbs
    super if @logged_user.company.is_owner?
  end

  def current_crumb
    case action_name
      when 'add' then :add_user
      when 'card' then @user.display_name
      when 'edit', 'current' then :edit_user
      else super
    end
  end

  def extra_crumbs
    crumbs = [
      {:title => :people, :url => '/administration/people'},
      {:title => @user.company.name, :url => "/company/card/#{@user.company.id}"}
    ]
    crumbs << {:title => @user.display_name, :url => "/user/card/#{@user.id}"} if action_name == 'update_permissions'
    crumbs
  end
end
