module UsMenuHelper
  def us_my_issues_url(project=nil)
    url_for(controller: :issues, action: :index, query_id: (Setting.plugin_unread_issues || {})['assigned_issues'].to_i, project_id: nil)
  end
end