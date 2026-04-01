class CreatePostAttachments < ActiveRecord::Migration[8.1]
  def change
    create_table :post_attachments do |t|
      t.references :post, null: false, foreign_key: true
      t.string :file_type, null: false
      t.string :url, null: false

      t.timestamps
    end
  end
end
