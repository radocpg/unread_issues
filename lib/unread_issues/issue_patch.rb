module UnreadIssues
  module IssuePatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        has_many :uis_issue_reads, -> { order("#{IssueRead.table_name}.read_date DESC") }, class_name: 'IssueRead', foreign_key: :issue_id, dependent: :delete_all
        has_one :uis_user_read, -> { where("#{IssueRead.table_name}.user_id = #{User.current.id}") }, class_name: 'IssueRead', foreign_key: :issue_id

        alias_method_chain :css_classes, :unread_issues

        before_save :ui_store_necessary_to_make_issue_read
        after_save :ui_make_issue_reed_if_needed
      end
    end

    module InstanceMethods
      def css_classes_with_unread_issues(user=User.current)
        s = css_classes_without_unread_issues(user)
        s << ' ui-unread' if self.uis_unread
        s << ' ui-updated' if self.uis_updated
        s
      end

      def uis_unread
        self.uis_user_read.nil?
      end

      def uis_updated(updated=self.updated_on)
        !!(self.uis_user_read && self.uis_user_read.read_date && self.updated_on && self.uis_user_read.read_date < updated)
      end

      def ui_make_issue_read
        begin
          issue_read = IssueRead.where(user_id: User.current.id, issue_id: self.id).first_or_initialize
          issue_read.read_date = Time.now
          issue_read.save
        rescue ActiveRecord::RecordNotUnique
          issue_read = IssueRead.where(user_id: User.current.id, issue_id: self.id).first
          if issue_read.present?
            issue_read.read_date = Time.now
            issue_read.save
          end
          # nothing
        end
      end

      private

      def ui_store_necessary_to_make_issue_read
        @ui_necessary_to_make_issue_read = self.new_record? || (!self.uis_unread && !self.uis_updated(self.updated_on_changed? ? self.updated_on_was : self.updated_on))
        true
      end

      def ui_make_issue_reed_if_needed
        return unless @ui_necessary_to_make_issue_read
        self.ui_make_issue_read
      end
    end
  end
end
