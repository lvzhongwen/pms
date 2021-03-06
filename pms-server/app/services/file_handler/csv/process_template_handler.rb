require 'csv'
module FileHandler
  module Csv
    class ProcessTemplateHandler<Base
      IMPORT_HEADERS=['Code', 'Type', 'Name', 'Template', 'Description', 'Wire NO', 'Component', 'Qty Factor', 'Bundle Qty', 'T1', 'T1 Strip Length', 'T2', 'T2 Strip Length', 'S1', 'S2']
      INVALID_CSV_HEADERS=IMPORT_HEADERS<<'Error MSG'

      def self.import(file)
        msg = Message.new
        begin
          validate_msg = validate_import(file)
          if validate_msg.result
            ProcessTemplate.transaction do
              CSV.foreach(file.file_path, headers: file.headers, col_sep: file.col_sep, encoding: file.encoding) do |row|
                row.strip
                type = row['Type'].to_i
                process_template = ProcessTemplate.new({code: row['Code'], type: row['Type'], template: row['Template'], description: row['Description'], name: row['Name']})
                case type
                  when ProcessType::AUTO
                    custom_fields = []
                    ['Wire NO', 'Component', 'Qty Factor', 'Bundle Qty', 'T1', 'T1 Strip Length', 'T2', 'T2 Strip Length', 'S1', 'S2'].each { |header|
                      custom_fields = custom_fields + header_to_custom_fields(header) if row[header] && row[header].to_i != 0
                    }
                    puts custom_fields
                    ProcessTemplateAuto.build_custom_fields(custom_fields, process_template).each do |cf|
                      process_template.custom_fields << cf
                    end
                  #
                  when ProcessType::SEMI_AUTO
                    #
                end
                process_template.save
              end
            end
            msg.result = true
            msg.content = 'Process Template 上传成功'
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
          puts "================"
          puts file.to_json

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

      def self.validate_row(row)
        msg = Message.new(contents: [])

        #验证唯一性
        #不能更新，只能手动更新
        template = ProcessTemplate.find_by_code(row['Code'])
        if template
          msg.contents << "Code:#{row['Code']}已经存在"
        end

        unless type = ProcessType.has_value?(row['Type'].to_i)
          msg.contents << "Type:#{row['Type']}不正确"
        end

        case type
          when ProcessType::AUTO
            #
          when ProcessType::SEMI_AUTO
            #
        end

        unless msg.result=(msg.contents.size==0)
          msg.content=msg.contents.join('/')
        end
        return msg
      end

      def self.header_to_custom_fields(header)
        case header
          when 'Wire NO'
            ['default_wire_nr']
          when 'Component'
            ['wire_nr']
          when 'Qty Factor'
            ['wire_qty_factor']
          when 'Bundle Qty'
            ['default_bundle_qty']
          when 'T1'
            ['t1', 't1_default_strip_length', 't1_qty_factor']
          when 'T1 Strip Length'
            ['t1_strip_length']
          when 'T2'
            ['t2', 't2_default_strip_length', 't2_qty_factor']
          when 'T2 Strip Length'
            ['t2_strip_length']
          when 'S1'
            ['s1', 's1_qty_factor']
          when 'S2'
            ['s2', 's2_qty_factor']
          else
            []
        end
      end
    end
  end
end