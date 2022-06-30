module UnreadIssues
  module IssueQueryPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        before_destroy :ui_validate_settings_before_destroy
        alias_method_chain :issues, :uis
        alias_method_chain :issue_ids, :uis
        alias_method_chain :available_columns, :uis
        alias_method_chain :initialize_available_filters, :uis
        alias_method_chain :joins_for_order_statement, :uis
        alias_method_chain :result_count_by_group, :uis
      end
    end

    module InstanceMethods
      def issues_with_uis(options={})
        options[:include] ||= []
        unless options[:include].include?(:uis_user_read)
          options[:include] << :uis_user_read
        end
        issues_without_uis(options)
      end

      def issue_ids_with_uis(options={})
        options[:include] ||= [ ]
        unless options[:include].include?(:uis_user_read)
          options[:include] << :uis_user_read
        end
        issue_ids_without_uis(options)
      end

      def available_columns_with_uis
        return available_columns_without_uis if @available_columns
        available_columns_without_uis

        @available_columns << QueryColumn.new(:uis_unread,
                                              sortable: "case when (#{IssueStatus.table_name}.is_closed = #{IssueQuery.connection.quoted_false}) and uis_ir.id is null then #{IssueQuery.connection.quoted_true} else #{IssueQuery.connection.quoted_false} end",
                                              groupable: "case when (#{IssueStatus.table_name}.is_closed = #{IssueQuery.connection.quoted_false}) and uis_ir.id is null then #{IssueQuery.connection.quoted_true} else #{IssueQuery.connection.quoted_false} end",
                                              caption: :unread_issues_label_filter_unread)
        @available_columns << QueryColumn.new(:uis_updated,
                                              sortable: "case when (#{IssueStatus.table_name}.is_closed = #{IssueQuery.connection.quoted_false}) and uis_ir.read_date < #{Issue.table_name}.updated_on then #{IssueQuery.connection.quoted_true} else #{IssueQuery.connection.quoted_false} end",
                                              groupable: "case when (#{IssueStatus.table_name}.is_closed = #{IssueQuery.connection.quoted_false}) and uis_ir.read_date < #{Issue.table_name}.updated_on then #{IssueQuery.connection.quoted_true} else #{IssueQuery.connection.quoted_false} end",
                                              caption: :unread_issues_label_filter_updated)
      end

      def initialize_available_filters_with_uis
        initialize_available_filters_without_uis
        add_available_filter('uis_unread',
                             type: :list,
                             values: [[l(:general_text_Yes), '1'], [l(:general_text_No), '0']],
                             name: l(:unread_issues_label_filter_unread)
        )
        add_available_filter('uis_updated',
                             type: :list,
                             values: [[l(:general_text_Yes), '1'], [l(:general_text_No), '0']],
                             name: l(:unread_issues_label_filter_updated)
        )
      end

      def joins_for_order_statement_with_uis(order_options)
        joins = [joins_for_order_statement_without_uis(order_options)]

        if order_options
          if order_options.include?(' uis_ir.')
            joins << "LEFT JOIN #{IssueRead.table_name} uis_ir ON uis_ir.issue_id = #{Issue.table_name}.id and uis_ir.user_id = #{User.current.id}"
          end
        end

        joins.compact!
        joins.any? ? joins.join(' ') : nil
      end

      def result_count_by_group_with_uis
        res = result_count_by_group_without_uis
        if self.group_by_column && %w(uis_unread uis_updated).include?(self.group_by_column.name.to_s)
          res.transform_keys { |key| key.to_i == 1 }
        else
          res
        end
      end

      def sql_for_uis_unread_field(field, operator, value)
        return '' if (value == [ ])
        case operator
          when '=', '!'
            if value.size == 1 && (value.include?('1') || value.include?('0'))
              if operator == '!'
                if value.include?('1')
                  value = ['0']
                else
                  value = ['1']
                end
              end
              "case when (
                    NOT EXISTS(
                      SELECT * FROM #{IssueRead.table_name} uis_ir
                        WHERE uis_ir.issue_id = #{Issue.table_name}.id and uis_ir.user_id = #{User.current.id})
                  ) then 1 else 0 end in (#{value.join(',')})"
            else
              if operator == '!'
                '(1=0)'
              else
                ''
              end
            end
        end
      end

      def sql_for_uis_updated_field(field, operator, value)
        return '' if (value == [ ])
        case operator
          when '=', '!'
            if value.size == 1 && (value.include?('1') || value.include?('0'))
              if operator == '!'
                if value.include?('1')
                  value = ['0']
                else
                  value = ['1']
                end
              end
              "EXISTS(
                SELECT * FROM #{IssueRead.table_name} uis_ir
                  WHERE uis_ir.issue_id = #{Issue.table_name}.id and
                        uis_ir.user_id = #{User.current.id} and
                        uis_ir.read_date #{value.include?('1') ? '<' : '>'} #{Issue.table_name}.updated_on)"
            else
              if operator == '!'
                '(1=0)'
              else
                ''
              end
            end
        end
      end

      private

      def ui_validate_settings_before_destroy
        if (Setting.plugin_unread_issues || {})['assigned_issues'].to_i == self.id
          self.errors.add(:base, l(:ui_error_cant_delete_query_used_in_plugin_settings, link: User.current.admin? ? "<a href='#{Redmine::Utils.relative_url_root}/settings/plugin/unread_issues'>#{l(:ui_label_module_settings_custom)}</a>" : l(:ui_label_module_settings_custom)).html_safe)
          false
        end
      end
    end
  end
end
