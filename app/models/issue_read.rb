class IssueRead < ActiveRecord::Base
  belongs_to :issue
  belongs_to :user

  attr_protected :id
end
