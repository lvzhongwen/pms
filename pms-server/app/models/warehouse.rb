class Warehouse < ActiveRecord::Base
  validates :nr, presence: true, uniqueness: {message: 'nr should be uniq'}


  PREFIX_WHOUSE={'^MC' => 'SRPL',
                 '^FC' => 'SRPL',
                 '^TC' => 'SRPL',
                 # '^XM' => '3Main',
                 # '^XF' => '3Floor',
                 # '^XT' => '3PL'
                 '^XM' => '3PL',
                 '^XF' => '3PL',
                 '^XT' => '3PL'
  }

  DEFAULT_WAREHOUSE='CUTTING_TMP'
  DEFAULT_POSITION='CUTTING_TMP'

  def self.get_whouse_by_position_prefix(position_nr)
    WarehouseRegex.all.each do |w|
      return w.warehouse_nr if /#{w.regex}/.match(position_nr)
    end
    return DEFAULT_WAREHOUSE
  end
end
