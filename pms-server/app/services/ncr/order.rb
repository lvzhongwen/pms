module Ncr
  class Order
    attr_accessor :production_order

    def initialize(production_order)
      self.production_order=production_order
      puts "#{production_order.class}--------------------------------"
    end

    def distribute
      msg=Message.new
      begin
        ProductionOrderItem.transaction do
          items=ProductionOrderItem.for_distribute(self.production_order)
          items.each do |item|
            # puts item.to_json
            begin
              puts "$$$$$#{write_order_api(item)}"
              response=RestClient.post(write_order_api(item), content_type: :json, accept: :json)
            rescue => e
              puts "#{e.class}---#{e.message}-----------------------------"
              # raise(e)
              if e.is_a?(Errno::ECONNREFUSED)
                item.update_attributes(state: ProductionOrderItemState::DISTRIBUTE_FAIL, message: e.message)
              end
            end
            puts '***********************************'
            puts response.body
            puts '***********************************'
            rb=JSON.parse(response.body)
            if rb['Result']
              item.update_attributes(state: ProductionOrderItemState::DISTRIBUTE_SUCCEED)
            else
              item.update_attributes(state: ProductionOrderItemState::DISTRIBUTE_FAIL, message: rb['Content'])
            end
            puts JSON.parse(response.body)['Result'].class
          end
        end
      rescue => e
        puts "#{e.class}--------------------------------"
        msg.result =false
        msg.content =e.message
        raise(e)
      end
      msg
    end

    def write_order_api(item)
      URI.encode "http://#{item.machine.ip}:9000/ncr/write_order/#{json_file_name(item)}/#{self.production_order.nr}/#{item.nr}/#{json_order_item_content(item)}"
    end

    def json_file_name(item)
      "#{self.production_order.nr}_#{item.nr}"
    end

    def json_order_item_content(item)
      kanban=item.kanban
      process_entity=kanban.process_entities.first
      # template=process_entity.process_template
      wire=Part.find_by_id(process_entity.value_wire_nr)
      t1=Part.find_by_id(process_entity.value_t1)
      t2=Part.find_by_id(process_entity.value_t2)
      s1=Part.find_by_id(process_entity.value_s1)
      s2=Part.find_by_id(process_entity.value_s2)


      json={
          production_order_id: self.production_order.id,
          production_order_nr: self.production_order.nr,
          item_id: item.id,
          item_nr: item.nr,
          wire_nr: wire.nr,
          wire_custom_nr: wire.custom_nr,
          wire_desc: 'wire default description',
          wire_length: process_entity.value_wire_qty_factor
      }

      unless t1.nil?
        tool1=Tool.where(part_id: t1.id).first
        json=json.merge({
                            t1_nr: t1.nr,
                            t1_custom_nr: t1.custom_nr,
                            t1_strip_length: process_entity.t1_strip_length,
                            t1_tool: tool1.nil? ? nil : tool1.nr
                        })
      end

      unless t2.nil?
        tool2=Tool.where(part_id: t1.id).first

        json=json.merge({
                            t2_nr: t2.nr,
                            t2_custom_nr: t2.custom_nr,
                            t2_strip_length: process_entity.t2_strip_length,
                            t1_tool: tool2.nil? ? nil : tool2.nr
                        })
      end

      unless s1.nil?
        json=json.merge({
                            s1_nr: s1.nr
                        })

      end


      unless s2.nil?
        json=json.merge({
                            s2_nr: s2.nr
                        })

      end

      # job
      json[:job]={
          Job: "J_#{self.production_order.nr}_#{item.nr}",
          ArticleKey: "A_#{self.production_order.nr}_#{item.nr}",
          TotalPieces: kanban.quantity,
          BatchSize: kanban.bundle,
          Name: "J_#{self.production_order.nr}_#{item.nr}",
          Hint: "Cutting Order: #{self.production_order.nr}. Cutting Position: #{item.nr}. Bundle quantity: #{kanban.bundle}. Total quantity: #{kanban.quantity}."
      }

      # article
      json[:article]={
          ArticleKey: "A_#{self.production_order.nr}_#{item.nr}",
          ArticleGroup: 'Group0',
          Name: "A_#{self.production_order.nr}_#{item.nr}",
          Hint: "A_#{self.production_order.nr}_#{item.nr}"
      }

      # wire
      json[:wire]={
          WireKey: wire.nr,
          WireGroup: 'Group0',
          ElectricalSizeMM2: process_entity.value_wire_qty_factor,
          Color: 'RD',
          Name: wire.nr,
          Hint: wire.nr
      }

      # terminal
      unless t1.nil?
        json[:terminal1]={TerminalKey: t1.nr,
                          TerminalGroup: 'Group0',
                          StrippingLength: process_entity.t1_strip_length,
                          Name: t1.nr,
                          Hint: 't1 description'}
      end

      unless t2.nil?
        json[:terminal2]={TerminalKey: t2.nr,
                          TerminalGroup: 'Group0',
                          StrippingLength: process_entity.t2_strip_length,
                          Name: t2.nr,
                          Hint: 't2 description'}
      end

      # seal
      unless s1.nil?
        json[:seal1]={TerminalKey: s1.nr,
                          TerminalGroup: 'Group0',
                          Color: 'YE',
                          Name: s1.nr,
                          Hint: 's1 description'}
      end

      unless s2.nil?
        json[:seal2]={TerminalKey: s2.nr,
                          TerminalGroup: 'Group0',
                          Color: 'YE',
                          Name: s2.nr,
                          Hint: 's2 description'}
      end

      puts "---------------------"
      puts json.to_json
      puts "------------------------"
      json.to_json
    end
  end
end