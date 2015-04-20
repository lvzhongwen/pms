module FileHandler
  module Excel
    class KanbanHandler<Base
      HEADERS=[
          'Nr', 'Quantity', 'Safety Stock', 'Copies',
          'Remark', 'Wire Nr', 'Product Nr', 'Type',
          'Bundle', 'Destination Warehouse',
          'Destination Storage', 'Process List','Operator'
      ]

      def self.export q = nil
        msg = Message.new
        begin
          tmp_file = full_tmp_path('kanbans.xlsx') unless tmp_file

          p = Axlsx::Package.new
          p.workbook.add_worksheet(:name => "Basic Worksheet") do |sheet|
            sheet.add_row HEADERS
            kanbans = []
            if q.nil?
              kanbans= Kanban.where("state is not ?",KanbanState::DELETED).all
            else
              kanbans = Kanban.search_for(q).select{|k| [KanbanState::INIT,KanbanState::RELEASED,KanbanState::LOCKED].include? k.state }
            end
            kanbans.each do |k|
              sheet.add_row [
                                k.nr,
                                k.quantity,
                                k.safety_stock,
                                k.copies,
                                k.remark,
                                k.wire_nr,
                                k.product_nr,
                                k.ktype,
                                k.bundle,
                                k.des_warehouse,
                                k.des_storage,
                                k.process_list,
                                'update'
                            ], types: [:string, nil, nil, nil, nil, :string, :string]
            end
          end
          p.use_shared_strings = true
          p.serialize(tmp_file)

          msg.result =true
          msg.content =tmp_file
        rescue => e
          puts e.backtrace
          msg.content = e.message
        end
        msg
      end

      def self.import_scan file
        msg = Message.new(contents: [])

        header = ['Wire Nr', 'Product Nr']

        book = Roo::Excelx.new file
        book.default_sheet = book.sheets.first

        2.upto(book.last_row) do |line|
          row = {}
          header.each_with_index do |k, i|
            row[k] = book.cell(line, i+1).to_s.strip # Strip
          end

          product = Part.where({nr: row['Product Nr'], type: PartType::PRODUCT}).first
          if product.nil?
            msg.contents << "Row #{line}: 总成号:#{row['Product Nr']}未找到!"
            puts "总成号未找到"
            next
          end

          wire = Part.find_by_nr("#{product.nr}_#{row['Wire Nr']}")

          if wire.nil?
            msg.contents << "Row #{line}: 线号:#{row['Wire Nr']}未找到!"
            puts "线号未找到"
            next
          end

          pe = ProcessEntity.joins(custom_values: :custom_field).where(
              {product_id: product.id, custom_fields: {name: "default_wire_nr"}, custom_values: {value: wire.id}}
          ).first

          kanban = pe.kanbans.first

          if kanban

            @kanban = kanban
            if @kanban.quantity <= 0
              next
            end
            if ProductionOrderItem.where(kanban_id: @kanban.id, state: ProductionOrderItemState::INIT).count > 0
              msg.contents<<"Row:#{line},已投卡"
              next
            end

            process_entity = @kanban.process_entities.first
            if process_entity && process_entity.process_parts.count > 0
              can_create = true
              parts = []
              process_entity.process_parts.each { |pe|
                part = pe.part
                # if (part.type == PartType::MATERIAL_TERMINAL) && (part.tool == nil)
                #   can_create = false
                # end
                if can_create #&& part.type == PartType::MATERIAL_TERMINAL
                  parts << part.nr
                end
              }

              # if process_entity.process_parts.select { |pe| pe.part.type == PartType::MATERIAL_TERMINAL }.count <= 0
              #   can_create = false
              # end

              if can_create
                unless (@order = ProductionOrderItem.create(kanban_id: @kanban.id, code: @kanban.printed_2DCode))
                  next
                end

                puts "新建订单成功：#{@kanban.nr},#{parts.join('-')}".green
              end
            else
              msg.contents<< "Row:#{line}步骤不存在！或步骤不消耗零件!"
            end
          end
        end

        msg.result = true
        if msg.contents.count > 0
          msg.content = msg.contents.join(";")
        else
          msg.content = "投卡成功!"
        end
        msg
      end

      def self.import file
        msg = Message.new
        book = Roo::Excelx.new file.full_path
        book.default_sheet = book.sheets.first

        validate_msg = validate_import(file)
        if validate_msg.result

          #validate file
          begin
            Kanban.transaction do
              2.upto(book.last_row) do |line|
                row = {}
                HEADERS.each_with_index do |k, i|
                  row[k] = book.cell(line, i+1).to_s.strip
                end

                product = Part.find_by_nr(row['Product Nr'])
                # 这段代码后面可能需要重新修改，因为项目刚启动，频繁修改卡量
                # 所以写在这里
                if row['Quantity'].to_i < row['Bundle'].to_i
                  row['Bundle'] = row['Quantity']
                end

                params = {}
                HEADERS.each { |header|
                  unless (row[header].nil? || header_to_attr(header).nil?)
                    params[header_to_attr(header)] = row[header]
                  end
                }
                params[:product_id] = product.id

                case row['Operator']
                  when 'new',''
                    kanban = Kanban.new(params)
                    process_nrs = row['Process List'].split(',')
                    kanban_process_entities = ProcessEntity.where({nr: process_nrs, product_id: product.id}).collect { |pe| KanbanProcessEntity.new({process_entity_id: pe.id}) }
                    kanban.kanban_process_entities = kanban_process_entities
                    kanban.state = KanbanState::RELEASED
                    kanban.save
                  when 'update'
                    kanban = Kanban.find_by_nr(row['Nr'])
                    kanban.update(params)
                    # 暴力法，一律删除然后重新创建
                    kanban.kanban_process_entities.destroy_all
                    process_nrs = row['Process List'].split(',')
                    kanban_process_entities = ProcessEntity.where({nr: process_nrs, product_id: product.id}).collect { |pe| KanbanProcessEntity.new({process_entity_id: pe.id}) }
                    kanban.kanban_process_entities = kanban_process_entities
                    kanban.save
                  when 'delete'
                    kanban = Kanban.find_by_nr(row['Nr'])
                    kanban.destroy
                end
              end
            end
            msg.result = true
            msg.content = "导入看板成功"
          rescue => e
            puts e.backtrace
            msg.result = false
            msg.content = e.message
          end
        else
          msg.result = false
          msg.content = validate_msg.content
        end
        msg
      end

      def self.validate_import file
        tmp_file=full_tmp_path(file.original_name)
        msg = Message.new(result:true)
        book = Roo::Excelx.new file.full_path
        book.default_sheet = book.sheets.first

        p = Axlsx::Package.new
        p.workbook.add_worksheet(:name => "Basic Worksheet") do |sheet|
          sheet.add_row HEADERS+['Error Msg']
          #validate file
          2.upto(book.last_row) do |line|
            row = {}
            HEADERS.each_with_index do |k, i|
              row[k] = book.cell(line, i+1).to_s.strip
            end

            mssg = validate_row(row, line)
            if mssg.result
              sheet.add_row row.values
            else
              if msg.result
                msg.result = false
                msg.content = "下载错误文件<a href='/files/#{Base64.urlsafe_encode64(tmp_file)}'>#{::File.basename(tmp_file)}</a>"
              end
              sheet.add_row row.values<<mssg.content
            end
          end
        end
        p.use_shared_strings = true
        p.serialize(tmp_file)
        msg
      end

      def self.validate_row row, line
        msg = Message.new(contents: [])

        product = Part.where({nr: row['Product Nr'], type: PartType::PRODUCT}).first

        case row['Operator']
          when 'delete'
            kanban = Kanban.find_by_nr(row['Nr'])
            unless kanban
              msg.contents << "Nr:#{row['Nr']},Kanban不存在"
            end
          when 'update'
            kanban = Kanban.find_by_nr(row['Nr'])
            unless kanban
              msg.contents << "Nr:#{row['Nr']},Kanban不存在"
            end
          when 'new',''
            if row['Nr'].present?
              msg.contents << "Nr:#{row['Nr']},新建时，不能输入Nr"
            end
          else
            msg.contents << "Operator,#{row['Operator']},操作错误"
        end

        # 验证总成号
        unless product
          msg.contents<<"Product Nr:#{Row['Product Nr']},总成号不存在"
        end

        # 验证工艺
        process_nrs = row['Process List'].split(',').collect { |penr| penr.strip }
        process_entities = ProcessEntity.where({nr: process_nrs, product_id: product.id})
        nrs= process_nrs - process_entities.collect { |pe| pe.nr }
        unless nrs.count==0
          msg.contents << "Process List: #{nrs}，工艺不存在!"
        end

        # 验证看板类型
        unless KanbanType.has_value?(row['Type'].to_i)
          msg.contents << "Type: #{row['Type']} 不正确"
        end

        unless msg.result=(msg.contents.size==0)
          msg.content=msg.contents.join('/')
        end
        msg
      end

      def self.header_to_attr header
        case header
          when "Nr"
            :nr
          when "Quantity"
            :quantity
          when "Safety Stock"
            :safety_stock
          when "Copies"
            :copies
          when "Remark"
            :remark
          when "Type"
            :ktype
          #when "Wire Length"
          #  :wire_length
          when "Bundle"
            :bundle
          when "Source Warehouse"
            :source_warehouse
          when "Source Storage"
            :source_storage
          when "Destination Warehouse"
            :des_warehouse
          when "Destination Storage"
            :des_storage
          else
            nil
        end
      end
    end
  end
end