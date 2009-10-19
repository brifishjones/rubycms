class CreatePages < ActiveRecord::Migration
  def self.up
    create_table :pages do |t|
      t.column :title,             :string
      t.column :filename_id,       :integer
      t.column :user_id,           :integer
      t.column :layout_id,         :string
      t.column :navigation_id,     :integer
      t.column :form_id,           :integer
      t.column :contact_id,        :integer
      t.column :subscription_id,   :integer
      t.column :keyword_id,        :integer
      t.column :robot_id,          :integer
      t.column :modified,          :datetime
      t.column :published,         :boolean
      t.column :valid_from,        :datetime
      t.column :valid_to,          :datetime
      t.column :breadcrumb,        :string
      t.column :content,           :text
      t.column :imagetop_id,       :integer
      t.column :imagetopinfo,      :text
      t.column :imageinfo,         :text
      t.column :bannerinfo, 	   :text
      t.column :galleryinfo,       :text
      t.column :imagesideinfo,	   :text
      t.timestamps
    end
  end

  def self.down
    drop_table :pages
  end
end
