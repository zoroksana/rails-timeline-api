class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :date, null: false
      t.text :description, null: false

      t.timestamps
    end

    add_index :posts, :date
  end
end
  end
end
