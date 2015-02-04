class CreateCustomValues < ActiveRecord::Migration
  def change
    create_table :custom_values do |t|
      t.string :customized_type
      t.integer :customized_id
      t.references :custom_field, index: true
      t.text :value

      t.timestamps
    end
    add_index :custom_values, [:customized_type, :customized_id]
  end
end
