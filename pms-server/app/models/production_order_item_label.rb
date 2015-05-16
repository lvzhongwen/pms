class ProductionOrderItemLabel < ActiveRecord::Base
  belongs_to :production_order_item

  IN_STORE=100
  ENTER_STOCK_FAIL=200


  after_create :update_production_order_item_state
  after_create :enter_stock
  after_create :move_stock

  def update_production_order_item_state
    unless self.production_order_item.state==ProductionOrderItemState::TERMINATED
      qty=self.production_order_item.production_order_item_labels.sum(:qty)
      if (kb =self.production_order_item.kanban) && (qty>=kb.quantity)
        self.production_order_item.update(state: ProductionOrderItemState::TERMINATED)
      end
    end
  end

  def enter_stock
    ItemLabelInStockWorker.perform_async(self.id)
  end

  def move_stock
    ItemLabelMoveStockWorker.perform_async(self.id,'SR01','SR01')
  end
end
