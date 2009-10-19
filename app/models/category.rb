class Category < ActiveRecord::Base
# contains the names of potential keywords, which are used in autocompletion of keyword list on a given page
  
  def unique
    self.name.strip!
    return false if Category.find(:first,
      :conditions => ["name = ?", self.name])
    return true
  end

end
