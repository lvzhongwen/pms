require 'csv'
module FileHandler
  module Csv
    class KanbanHandler<Base
      IMPORT_HEADERS=['Nr', 'Quantity', 'Safety Stock', 'Copies', 'Remark',
                      'Wire Nr', 'Product Nr', 'Type', 'Wire Length', 'Bundle',
                      'Source Warehouse', 'Source Storage', 'Destination Warehouse', 'Destination Storage', 'Process List']
      INVALID_CSV_HEADERS=IMPORT_HEADERS<<'Error MSG'

      def self.import(file)
        msg = Message.new
        begin
          validate_msg = validate_import(file)
          if validate_msg.result
            Kanban.transaction do
              CSV.foreach(file.file_path, headers: file.headers, col_sep: file.col_sep, encoding: file.encoding) do |row|
                row.strip

                product = Part.find_by_nr(row['Product Nr'])

                if row['Quantity'].to_i < row['Bundle'].to_i
                  row['Bundle'] = row['Quantity']
                end
                if row['Nr']
                  kanban = Kanban.find_by_nr(row['Nr'])
                  #更新,只能更新基础信息
                  kanban.update({quantity: row['Quantity'], safety_stock: row['Safety Stock'], copies: row['Copies'], remark: row['Remark'], bundle: row['Bundle'],
                                 source_warehouse: row['Source Warehouse'], source_storage: row['Source Storage'], des_warehouse: row['Destination Warehouse'],
                                 des_storage: row['Destination Storage']})
                else
                  #新建
                  #part_id = (part = Part.find_by_nr("#{row['Product Nr']}_#{row['Wire Nr']}")).nil? ? nil : part.id

                  kanban = Kanban.new({quantity: row['Quantity'], safety_stock: row['Safety Stock'], copies: row['Copies'], remark: row['Remark'],
                                       product_id: product.id, ktype: row['Type'], bundle: row['Bundle'],
                                       source_warehouse: row['Source Warehouse'], source_storage: row['Source Storage'], des_warehouse: row['Destination Warehouse'],
                                       des_storage: row['Destination Storage'], state: KanbanState::RELEASED})
                  process_nrs = row['Process List'].split(',')
                  kanban_process_entities = ProcessEntity.where({nr: process_nrs, product_id: product.id}).collect { |pe| KanbanProcessEntity.new({process_entity_id: pe.id}) }
                  kanban.kanban_process_entities = kanban_process_entities
                  kanban.save
                end
              end
            end
            msg.result = true
            msg.content = 'Kanban 上传成共'
          else
            msg.result = false
            msg.content = validate_msg.content
          end
        rescue => e
          puts e.backtrace
          msg.content = e.message
        end
        return msg
      end

      def self.validate_import(file)
        tmp_file=full_tmp_path(file.file_name)
        msg=Message.new(result: true)
        CSV.open(tmp_file, 'wb', write_headers: true,
                 headers: INVALID_CSV_HEADERS, col_sep: file.col_sep, encoding: file.encoding) do |csv|
          CSV.foreach(file.file_path, headers: file.headers, col_sep: file.col_sep, encoding: file.encoding) do |row|
            mmsg = validate_row(row)
            if mmsg.result
              csv<<row.fields
            else
              if msg.result
                msg.result=false
                msg.content = "请下载错误文件<a href='/files/#{Base64.urlsafe_encode64(tmp_file)}'>#{::File.basename(tmp_file)}</a>"
              end
              csv<<(row.fields<<mmsg.content)
            end
          end
        end
        return msg
      end

      def self.export_routing_error(user_agent)
        msg = Message.new
        begin
          tmp_file = KanbanHandler.full_tmp_path('看板步骤不一致.csv') unless tmp_file

          CSV.open(tmp_file, 'wb', write_headers: true,
                   headers: ['ID', 'NR', 'Product Nr', 'Process List', 'Desc'],
                   col_sep: SEPARATOR, encoding: ProcessEntityHandler.get_encoding(user_agent)) do |csv|
            Kanban.all.each_with_index do |k|
              null_process_parts = false
              if (pes = k.process_entities.select { |pe| pe.product_id != k.product_id }).count>0
                csv<<[
                    k.id,
                    k.nr,
                    k.product_nr,
                    pes.collect { |pe|
                      "#{pe.nr},#{pe.product_nr}"
                    }.join(";"),
                    '不存在消料'
                ]
              end

              pes = []
              k.process_entities.each { |pe|
                if pe.process_parts.count == 0
                  null_process_parts = true
                  pes << "#{pe.id}:#{pe.nr}"
                end
              }
              if null_process_parts
                csv<<[
                    k.id,
                    k.nr,
                    k.product_nr,
                    pes.join("|"),
                    '步骤与看板总成号不一致'
                ]
              end

              if k.des_storage.nil? || k.des_storage.blank?
                csv<<[
                    k.id,
                    k.nr,
                    k.product_nr,
                    "",
                    '看板目标库位不存在'
                ]
              end
            end
          end
          msg.result =true
          msg.content =tmp_file
        rescue => e
          msg.content =e.message
        end
        msg
      end

      def self.validate_row(row)
        msg = Message.new({result: true, contents: []})

        kanban = Kanban.find_by_nr(row['Nr'])

        #如果存在Nr，表示更新，需要验证是否存在
        if row['Nr'] && kanban.nil?
          msg.contents << "Nr: row['Nr'] 不存在"
        end

        #如果是更新KANBAN，不能更新总成号和线号
        if kanban && (row["Product Nr"] != kanban.product_nr || "#{row['Product Nr']}_#{row['Wire Nr']}" != kanban.part_nr)
          msg.contents << "Wire Nr: #{row['Wire Nr']},Product Nr: #{row['Product nr']} 不能修改"
        end

        #验证总成号
        product = nil
        unless product = Part.where({nr: row['Product Nr'], type: PartType::PRODUCT}).first
          msg.contents << "Product Nr: #{row['Product Nr']} 不存在"
        end

        #验证工艺
        process_nrs = row['Process List'].split(',').collect { |penr| penr.strip }
        process_entities = ProcessEntity.where({nr: process_nrs, product_id: product.id})

        unless process_entities.count == process_nrs.count
          msg.contents << "Process List: #{process_nrs - process_entities.collect { |pe| pe.nr }}，工艺不存在!"
        end

        if kanban.nil? && row['Wire Nr'].present? &&Part.where({nr: "#{row['Product Nr']}_#{row['Wire Nr']}"}).count <= 0
          msg.contents << "Wire Nr:#{row['Wire Nr']} 不存在"
        end

        #验证看板类型
        unless KanbanType.has_value?(row['Type'].to_i)
          msg.contents << "Type: #{row['Type']} 不正确"
        end

        case row['Type'].to_i
          when KanbanType::WHITE
            if process_entities.count != 1
              msg.contents << "Process List: #{row['Process List']} 白卡只能添加一个Routing"
            end

            if process_entities.first.process_template.type != ProcessType::AUTO
              msg.contents << "Process List: #{row['Process List']} 白卡只能添加全自动Routing"
            end
          when KanbanType::BLUE

        end

        #TODO 验证库位

        unless msg.result=(msg.contents.size==0)
          msg.content=msg.contents.join('/')
        end
        return msg
      end
    end
  end
end