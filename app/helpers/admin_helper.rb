module AdminHelper

  def create_list(user_list = nil, group_list = nil)
  # given a privilege generate the appropriate list based on the type:
  # called by _privilege.rhtml
    grp = ""
    usr = ""
    bul = ""
    if user_list != nil && user_list != ""
      ua = []
      user_list.split.each do |j|
        if j == "*"
          ua << "*"
        else
          u = User.find(:first,
                  :conditions => ["id = ?", j])
          ua << u.name if u != nil 
          ua << "*" if j == "*" 
        end 
      end
      usr = ua.sort.join(", ")
    end
    if group_list != nil && group_list != ""
      grp = "<em>" + group_list.split.sort.join(", ") + "</em>"
    end  
       
    bul = " &bull; " if group_list != nil && grp != "" && user_list != nil && usr != ""
    
    return grp + bul + usr
  end

end
