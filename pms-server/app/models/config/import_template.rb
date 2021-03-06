class ImportTemplate
  BOM_CSV_TEMPLATE='bom.csv'
  PART_CSV_TEMPLATE='part.csv'
  PART_UPDATE_CSV_TEMPLATE='part_update.csv'
  PROCESS_TEMPLATE_CSV_TEMPLATE='process_template.csv'
  PROCESS_ENTITY_AUTO_CSV_TEMPLATE='process_entity_auto.csv'
  PROCESS_ENTITY_AUTO_EXCEL_TEMPLATE='process_entity_auto.xlsx'
  PROCESS_ENTITY_SEMI_AUTO_CSV_TEMPLATE='process_entity_semi_auto.csv'
  PROCESS_ENTITY_SEMI_AUTO_EXCEL_TEMPLATE='process_entity_semi_auto.xlsx'
  KANBAN_CSV_TEMPLATE='kanban.csv'
  KANBAN_EXCEL_TEMPLATE='kanban.xlsx'
  KANBAN_SCAN_EXCEL_TEMPLATE='kanban_scan.xlsx'
  KANBAN_FINISH_SCAN_EXCEL_TEMPLATE='kanban_finish_scan.xlsm'
  KANBAN_UPDATE_EXCEL_TEMPLATE='kanban_update_quantity.xlsx'
  KANBAN_LOCK_EXCEL_TEMPLATE='kanban_lock.xlsx'
  KANBAN_RELEASE_EXCEL_TEMPLATE='kanban_release.xlsx'
  KANBAN_GET_LIST_CSV_TEMPLATE='get_kanban_list.csv'
  KANBAN_UPDATE_BASE_TEMPLATE='kanban_update_base_template.csv'
  KANBAN_TRANSPORT_EXCEL_TEMPLATE='kanban_transport.xlsx'
  MACHINE_CSV_TEMPLATE='machine.csv'
  MACHINE_COMBINATION_CSV_TEMPLATE='machine_combination.csv'
  MACHINE_TIME_RULE_EXCEL_TEMPLATE='machine_time_rule.xlsx'
  TOOL_CSV_TEMPLATE='tool.csv'
  PART_POSITION_CSV_TEMPLATE='part_position.csv'
  MASTER_BOM_EXCEL_TEMPLATE='master_bom_template.xlsx'
  MASTER_BOM_DELETE_EXCEL_TEMPLATE='master_bom_delete_template.xlsx'
  ORDER_BOM_CSV_TEMPLATE='order_transport.csv'
  ORDER_BOM_EXCEL_TEMPLATE='order_transport.xlsx'
  CRIMP_CONFIGRATION_EXCEL_TEMPLATE='crimp_configration.xlsx'
  CRIMP_CONFIGRATION_ITEM_EXCEL_TEMPLATE='crimp_configration_item.xlsx'
  WIRE_GROUP_EXCEL_TEMPLATE='wire_group.xlsx'
  CUSTOM_DETAIL_EXCEL_TEMPLATE='custom_detail.xlsx'
  MEASURED_VALUE_RECORD_EXCEL_TEMPLATE='measured_value_record.xlsx'

  def self.method_missing(method_name, *args, &block)
    if method_name.to_s.include?('_template')
      return Base64.urlsafe_encode64(File.join($template_file_path, self.const_get(method_name.upcase)))
    else
      super
    end
  end
end