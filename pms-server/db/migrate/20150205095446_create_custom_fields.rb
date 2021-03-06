class CreateCustomFields < ActiveRecord::Migration
  def change
    create_table :custom_fields do |t|
      t.string :custom_fieldable_type
      t.integer :custom_fieldable_id

      t.string :type #, null: false
      t.string :name, null: false
      t.string :field_format, null: false
      t.text :possible_values
      t.string :regexp
      t.integer :min_length
      t.integer :max_length
      t.boolean :is_required, default: false, null: false
      t.boolean :is_for_all, default: false, null: false
      t.boolean :is_filter, default: false, null: false
      t.boolean :is_for_out_stock, default: false, null: false
      # t.string :out_stock_field
      t.integer :position, default: 1
      t.boolean :searchable, default: false, null: false
      t.text :default_value
      t.boolean :editable, default: true
      t.boolean :visible, default: true, null: false
      t.boolean :multiple, default: false
      t.text :format_store
      t.boolean :is_query_value, default: false
      # t.boolean :is_auto_query_value, default: false
      t.text :validate_query
      t.string :validate_message
      t.text :value_query
      t.text :description

      t.timestamps
    end
    add_index :custom_fields, :type
    add_index :custom_fields, [:id, :type]
    add_index :custom_fields, [:custom_fieldable_id, :custom_fieldable_type], name: 'custom_fieldable_index'
  end
end
