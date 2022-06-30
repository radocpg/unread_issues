module UnreadIssues
  module QueriesControllerPatch
    def self.included(base)
      base.send :include, InstanceMethods

      base.class_eval do
        alias_method_chain :redirect_to_items, :ui
      end
    end

    module InstanceMethods
      def redirect_to_items_with_ui(options={})
        if request.delete? && @query && @query.errors.present?
          flash[:error] = view_context.error_messages_for(@query).gsub(" id='errorExplanation'", '')
          options[:query_id] = @query.id
        end

        redirect_to_items_without_ui(options)
      end
    end
  end
end