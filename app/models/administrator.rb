class Administrator < ActiveRecord::Base
  
  validates_format_of :name,
                      :with => /^[A-Za-z0-9]+$/,
                      :message => "is invalid (may only contain letters or numbers)."
  validates_uniqueness_of :name,
                          :on => :create,
                          :message => "is already in use."
                          

  def unique
    return false if Administrator.find(:first,
      :conditions => ["name = ?", self.name])
    return true
  end

end
