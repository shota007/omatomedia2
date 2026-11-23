class CreateNpoSources < ActiveRecord::Migration[7.0]
  def change
    create_table :npo_sources do |t|
      t.references :npo, null: false, foreign_key: true
      t.string :source_type
      t.string :url
      t.string :title
      t.datetime :fetched_at
      t.text :note

      t.timestamps
    end
  end
end
