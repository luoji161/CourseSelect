class CoursesController < ApplicationController
  include CoursesHelper
  before_action :student_logged_in, only: [:select, :quit, :list, :scorecount, :timetable]
  before_action :teacher_logged_in, only: [:new, :create, :edit, :destroy, :update, :open, :close]#add open by qiao
  before_action :logged_in, only: :index

  #-------------------------for teachers----------------------

  def new
    @course=Course.new
  end

  def create
    @course = Course.new(course_params)
    if @course.save
      current_user.teaching_courses<<@course
      redirect_to courses_path, flash: {success: "新课程申请成功"}
    else
      flash[:warning] = "信息填写有误,请重试"
      render 'new'
    end
  end

  def edit
    @course=Course.find_by_id(params[:id])
  end

  def update
    @course = Course.find_by_id(params[:id])
    if @course.update_attributes(course_params)
      flash={:info => "更新成功"}
    else
      flash={:warning => "更新失败"}
    end
    redirect_to courses_path, flash: flash
  end

  def open
    @course=Course.find_by_id(params[:id])
    @course.update_attributes(open: true)
    redirect_to courses_path, flash: {:success => "已经成功开启该课程:#{ @course.name}"}
  end

  def close
    @course=Course.find_by_id(params[:id])
    @course.update_attributes(open: false)
    redirect_to courses_path, flash: {:success => "已经成功关闭该课程:#{ @course.name}"}
  end

  def destroy
    @course=Course.find_by_id(params[:id])
    current_user.teaching_courses.delete(@course)
    @course.destroy
    flash={:success => "成功删除课程: #{@course.name}"}
    redirect_to courses_path, flash: flash
  end

  #-------------------------for students----------------------

  def list
    #-------QiaoCode--------
    @courses = Course.where(:open=>true)
    @course = @courses-current_user.courses
    @course_type = get_course_info(@course, 'course_type')
    @course_time = get_course_info(@course, 'course_time')
    #
    if request.post?
      res=[]
      @course.each do |course|
        if check_course_condition(course, 'course_time', params['course']['course_time'])and
          check_course_condition(course, 'course_type', params['course']['course_type'])and
          check_course_keyword(course,'name',params['keyword'])
          res << course
        end
       end
      @course = res
    end
    @course = @course.paginate(:page => params[:page], :per_page =>5)
  end

  def select
    @course=Course.find_by_id(params[:id])
    current_user.courses<<@course
    flash={:suceess => "成功选择课程: #{@course.name}"}
    redirect_to courses_path, flash: flash
  end

  def quit
    @course=Course.find_by_id(params[:id])
    current_user.courses.delete(@course)
    flash={:success => "成功退选课程: #{@course.name}"}
    redirect_to courses_path, flash: flash
  end
  
  #------显示课表--把已选的课程传给课表  
  def timetable  
    @course = current_user.courses  
    @grades = current_user.grades  
      
    rated_courses = []  
    # 将已经打分的课程从课程表中去掉  
    @grades.each do |grade|  
      if grade.user.name == current_user.name and grade.grade != nil and grade.grade != '' and grade.grade > 0  
        rated_courses << grade.course  
      end  
    end      
    @course_credit = get_course_info(@course, 'credit')  
    @current_user_course=current_user.courses  
    @user=current_user  
    # 去掉已经打分的课程  
    @course = @course - rated_courses  
    @course_time_table = get_current_curriculum_table(@course, @user)#当前课表  
  end 
  
  
  # 统计学分
  def scorecount
    @course = current_user.courses
    @grades = current_user.grades
    
    @public_required = ''
    @course.each do |course|
      if course.course_type == '公共必修课'
        @public_required << course.name
      end
    end
    
    @get_public_required = ''
    @grades.each do |grade|
      if grade.course.course_type == '公共必修课'
        @get_public_required << grade.course.name
      end
    end
    
    @course_credit = get_course_info(@course, 'credit')
    @current_user_courses = current_user.courses
    @user = current_user
    @course_score_table = get_course_score_table(@course, @user)
  end

  #-------------------------for both teachers and students----------------------

  def index
    @course=current_user.teaching_courses.paginate(page: params[:page], per_page: 4) if teacher_logged_in?
    @course=current_user.courses.paginate(page: params[:page], per_page: 4) if student_logged_in?
  end


  private

  # Confirms a student logged-in user.
  def student_logged_in
    unless student_logged_in?
      redirect_to root_url, flash: {danger: '请登陆'}
    end
  end

  # Confirms a teacher logged-in user.
  def teacher_logged_in
    unless teacher_logged_in?
      redirect_to root_url, flash: {danger: '请登陆'}
    end
  end

  # Confirms a  logged-in user.
  def logged_in
    unless logged_in?
      redirect_to root_url, flash: {danger: '请登陆'}
    end
  end

  def course_params
    params.require(:course).permit(:course_code, :name, :course_type, :teaching_type, :exam_type,
                                   :credit, :limit_num, :class_room, :course_time, :course_week)
  end


end
