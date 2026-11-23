class CreateNpos < ActiveRecord::Migration[7.0]
  def change
    create_table :npos do |t|
      t.string :name
      t.string :name_kana
      t.string :corporate_number
      t.string :prefecture
      t.string :city
      t.string :address
      t.string :representative_name
      t.date :established_on
      t.string :website_url
      t.string :phone
      t.string :email
      t.text :summary
      t.integer :status, null: false, default: 0
      t.datetime :last_verified_at

      t.timestamps
    end

    add_index :npos, :corporate_number, unique: true
    add_index :npos, :name
    add_index :npos, :status
  end
end
