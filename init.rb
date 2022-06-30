Redmine::Plugin.register :unread_issues do
  name 'Unread Issues plugin'
  author 'Vladimir Pitin, Danil Kukhlevskiy, Kovalevsky Vasil'
  description 'This is a plugin for Redmine, that marks unread issues'
  version '2.2.1'
  url 'http://rmplus.pro/redmine/plugins/unread_issues'
  author_url 'http://rmplus.pro'

  requires_redmine '3.4.1'

  settings partial: 'unread_issues/settings',
           default: { 'assigned_issues' => '', }

  project_module :issue_tracking do
    permission :view_issue_view_stats, issue_view_stats: [:view_stats]
  end

  if Redmine::Plugin.installed?(:magic_my_page)
    delete_menu_item :top_menu, :my_page
    menu :top_menu, :my_page, { controller: 'my', action: 'page' }, caption: Proc.new { User.current.ui_my_page_caption },  if: Proc.new { User.current.logged? }, first: true
  end
  menu :top_menu, :us_my_issues, :us_my_issues_url, caption: Proc.new { User.current.ui_my_issues_caption }, if: Proc.new { User.current.logged? }, first: true
end

Rails.application.config.to_prepare do
  unless Issue.included_modules.include?(UnreadIssues::IssuePatch)
    Issue.send(:include, UnreadIssues::IssuePatch)
  end
  unless User.included_modules.include?(UnreadIssues::UserPatch)
    User.send(:include, UnreadIssues::UserPatch)
  end
  unless IssuesController.included_modules.include?(UnreadIssues::IssuesControllerPatch)
    IssuesController.send(:include, UnreadIssues::IssuesControllerPatch)
  end
  unless IssueQuery.included_modules.include?(UnreadIssues::IssueQueryPatch)
    IssueQuery.send(:include, UnreadIssues::IssueQueryPatch)
  end
  unless QueriesController.included_modules.include?(UnreadIssues::QueriesControllerPatch)
    QueriesController.send(:include, UnreadIssues::QueriesControllerPatch)
  end
  ActionView::Base.send(:include, UsMenuHelper)
end

Rails.application.config.after_initialize do
  plugins = { a_common_libs: '2.4.0' }
  plugin = Redmine::Plugin.find(:unread_issues)
  plugins.each do |k,v|
    begin
      plugin.requires_redmine_plugin(k, v)
    rescue Redmine::PluginNotFound => ex
      raise(Redmine::PluginNotFound, "Plugin requires #{k} not found")
    end
  end
end

require 'unread_issues/hooks_views'