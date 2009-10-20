# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)
        
  fn = Filename.create(:name => "new-page")
  u = User.find(:first, :conditions => ["name = ?", 'admin'])
  Page.create(:filename_id => fn.id , :published => false, :modified => Time.now , :user_id => u.id)
  
  Privilege.create(:regex => '^new\-page$', :user_read_list => "*", :user_publish_list => u.id.to_s)
