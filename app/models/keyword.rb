class Keyword < ActiveRecord::Base
# keyword list with hints of keywords from the model class 'Category'
  has_many :pages
  
  # construct array of keys, remove leading and trailing whitespace, alphabetize, then recreate list
  def clean
    keylist = self.list.split(',')
    keylist.each { |i| i.strip! }
    keylist.sort! { |a,b| a.downcase <=> b.downcase }
    self.list = keylist.join(', ')
  end

  def unique
    clean
    return false if Keyword.find(:first,
      :conditions => ["list = ?", self.list])
    return true
  end
end
