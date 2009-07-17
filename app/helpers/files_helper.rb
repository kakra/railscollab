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

module FilesHelper
  def page_title
    case action_name
      when 'index' then @current_folder.nil? ? :files.l : :folder_name.l_with_args(:folder => @current_folder.name)
      else super
    end
  end

  def current_tab
    :files
  end

  def current_crumb
    case action_name
      when 'index', 'browse_folder' then @current_folder.nil? ? :files : @current_folder.name
      when 'attach_to_object' then :attach_files
      when 'edit' then :edit_time
      when 'file_details' then @file.filename
      else super
    end
  end

  def extra_crumbs
    crumbs = []
    crumbs << {:title => :files, :url => "/project/#{@active_project.id}/files"} unless action_name == 'index' && @current_folder.nil?
    crumbs << {:title => @folder.name, :url => @folder.object_url} unless action_name != 'file_details' || @folder.nil?
    crumbs
  end

  def additional_stylesheets
    case action_name
      when 'attach_to_object' then ['project/attach_files']
      else ['project/files']
    end
  end
end
