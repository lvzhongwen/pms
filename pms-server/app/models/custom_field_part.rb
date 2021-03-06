class CustomFieldPart<CustomField
  # before_save :validate_query

  def validate_field(args)
    validate_validate_query(args)
  end

  def validate_validate_query(args)
    args=self.class.parse_args(args)
    puts "----#{args}".red
    query=field_to_query(args)
    puts "#{query}".red
    # lt is not safe, should improve later
    unless value=eval(query)
     # raise('未通过验证查询')
      return nil
    else
      return value
    end
  end

  def get_field_value(args)
    args=self.class.parse_args(args)
    validate_validate_query(args)
    return eval(field_to_query(args))
  end

  def self.build_default(field_format, name, type, position=1)
    new(name: name,
        is_query_value: true,
        field_format: field_format,
        value_query: 'Part.find_by_id(#).nr',
        validate_query: 'Part.find_by_nr(#)',
        is_for_out_stock: true,
        position: position,
        description: "dynamic template default custom field, #{name}")
  end

  private
  def field_to_query(args)
    self.validate_query.gsub('#').each_with_index { |v, i| "'#{args[i]}'" }
  end
end