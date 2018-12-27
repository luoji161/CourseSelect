require 'set'

module CoursesHelper
    
    def data_transform(date)
        if date.include?"周一"
            return'1'
        elsif date.include?"周二"
            return '2'
        elsif date.include?"周三"
            return '3'
        elsif date.include?"周四"
            return '4'
        elsif date.include?"周五"
            return '5'
        elsif date.include?"周六"
            return '6'
        elsif date.include?"周天"
            return '7'
        end
    end
    
    def get_course_info(course, type)
        res = Set.new
        course.each do |course|
            res.add(course[type])
        end
        res.to_a.sort
    end
    
    def check_course_condition(course, key, value)
        if key == 'course_time'
            if value == '' or data_transform(course[key]) == value
                return true
            end
        elsif value == '' or course[key] == value
            return true
        end
        false
    end
    
    def check_course_keyword(course, key, value)
        if value == '' or value == nil or course[key].include?value
            return true
        end
        false
    end
    
    def get_course_score_table(course, user)
        # 二维数组，表示学分
        score_table = Array.new(2) { Array.new(3,0.0) }
        
        # 遍历用户已经选的课
        course.each do |cur|
            f_credit = cur.credit.split('/')[1].to_f
            # 课程学分按照类别进行分别计算
            if cur.course_type == '公共选修课'
                score_table[0][0] += f_credit
                if !is_end_course(cur, user)
                    score_table[1][0] += f_credit
                    score_table[1][2] += f_credit
                end
            elsif cur.course_type =='公共必修课'
                if !is_end_course(cur, user)
                    score_table[1][2] += f_credit
                end
            elsif cur.course_type.include?'专业' or cur.course_type.include?'一级学科'
                score_table[0][1] += f_credit
                if !is_end_course(cur, user)
                    score_table[1][1] += f_credit
                    score_table[1][2] += f_credit
                end
            end
            score_table[0][2] += f_credit
        end
        score_table
    end
    
    def is_end_course(course, user)
        @grades = course.grades
        @is_open = false
        @grades.each do |grade|
            if grade.user.name ==user.name
                @is_open == true
            end
        end
        return @is_open
    end
end