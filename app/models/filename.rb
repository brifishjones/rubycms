class Filename < ActiveRecord::Base

  has_many :pages
  
  validates_format_of :name,
                      :with => /^(?!\/?edit|\/?staging\/?admin|\/?rubycms)(.*)$/,
                      :message => "contains a reserved name or is not in a valid format."

  def clean
    self.name.gsub!(/\/{2,}/, "/")
    self.name = self.name.strip.chomp("/").reverse.chomp("/").reverse
    self.name.gsub!(/[^\w\-\/]/, "")
    #self.name.gsub!(/_/, "-")
  end

  def unique
    clean
    return false if Filename.find(:first,
      :conditions => ["name = ?", self.name])
    return true
  end

end
