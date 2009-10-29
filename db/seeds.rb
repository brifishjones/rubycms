# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)
        
  fn = Filename.create(:name => "add-new-page")
  u = User.find(:first, :conditions => ["name = ?", 'admin'])
  Page.create(:filename_id => fn.id , :title => '(New page)', :published => false, :modified => Time.now , :user_id => u.id, :content => '<p>To add a new page:</p>
    <ul><li>Replace <em>add-new-page</em> with the full path of the new page in the filename field below, and click <em>Save</em>.</li>
    <li>Edit the newly saved page by clicking the rightmost breadcrumb, selecting the the dot to the left of the username, or replacing the word <em>staging</em> with the word <em>edit</em> in the url.</li>
    <li>Alter the title, layout, and images.</li>
    <li>Replace this text with the desired main body content.</li></ul>')

  
  Privilege.create(:regex => '^add\-new\-page$', :user_read_list => "*", :user_publish_list => u.id.to_s)
