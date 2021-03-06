module UnreadIssues
  module UserPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        has_many :issue_reads, dependent: :delete_all
        has_many :assigned_issues, class_name: 'Issue' , foreign_key: 'assigned_to_id'
      end
    end

    module InstanceMethods
      def ui_my_page_caption
        s = "<span class='my_page'>#{l(:my_issues_on_my_page)}</span> "
        if Redmine::Plugin.installed?(:magic_my_page)
          s << self.ui_my_page_counts
        end
        s.html_safe
      end

      def ui_my_issues_caption
        s = "<span class='my_page'>#{l(:label_us_my_issues)}</span>"
        s << self.ui_my_page_counts
        s.html_safe
      end

      def ui_my_page_counts
        s = self.acl_ajax_counter('ui_assigned_issues_count', { period: 0, css: '', sync_count: Proc.new { @ui_issues_counts ||= self.ui_issues_counts; @ui_issues_counts[:assigned] }})
        s << self.acl_ajax_counter('ui_unread_issues_count', { period: 0, css: 'unread', sync_count: Proc.new { @ui_issues_counts ||= self.ui_issues_counts; @ui_issues_counts[:unread] }})
        s << self.acl_ajax_counter('ui_updated_issues_count', { period: 0, css: 'updated', sync_count: Proc.new { @ui_issues_counts ||= self.ui_issues_counts; @ui_issues_counts[:updated] }})
        s.html_safe
      end

      def ui_assigned_issues_count(view_context=nil, params=nil, session={})
        self.ui_issues_counts(:assigned)[:assigned]
      end

      def ui_unread_issues_count(view_context=nil, params=nil, session={})
        self.ui_issues_counts(:unread)[:unread]
      end

      def ui_updated_issues_count(view_context=nil, params=nil, session={})
        self.ui_issues_counts(:updated)[:updated]
      end

      def ui_issues_counts(count_keys=[])
        count_keys = Array.wrap(count_keys)
        if count_keys.blank?
          count_keys = [:assigned, :unread, :updated]
        end
        counts = {}
        count_keys.each do |k|
          counts[k.to_sym] = 0
        end

        Setting.plugin_unread_issues = {} unless Setting.plugin_unread_issues.is_a?(Hash)
        return counts if (Setting.plugin_unread_issues || {})['assigned_issues'].to_i == 0

        begin
          query = IssueQuery.find((Setting.plugin_unread_issues || {})['assigned_issues'].to_i)
          query.group_by = ''
        rescue ActiveRecord::RecordNotFound
          return counts
        end

        return counts if query.blank?

        counts[:assigned] = query.issue_ids.size if counts.has_key?(:assigned)
        counts[:unread] = query.issue_ids(conditions: "#{IssueRead.table_name}.read_date is null").size if counts.has_key?(:unread)
        counts[:updated] = query.issue_ids(conditions: "#{IssueRead.table_name}.read_date < #{Issue.table_name}.updated_on").size if counts.has_key?(:updated)

        counts
      end
    end
  end
end
