class IssueReadsController < ApplicationController
  def view_stats
    @issue = Issue.find(params[:id])
    if Redmine::Plugin.installed?(:redmine_issue_tabs) &&
       (
        User.current.admin? || (Redmine::Plugin.installed?(:global_roles) && User.current.global_permission_to?(:view_issue_view_stats)) ||
        (!Redmine::Plugin.installed?(:global_roles) && User.current.allowed_to?(:view_issue_view_stats, @issue.project))
       )
      @issue_reads = @issue.uis_issue_reads
    else
      render_403
    end
  end
end
