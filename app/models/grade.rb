class Grade < ActiveRecord::Base
  belongs_to :course
  belongs_to :user
  attr_reader :open
end
# 定义属性访问器，使得外部可以访问课程的open属性
