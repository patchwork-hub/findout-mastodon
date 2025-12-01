# == Schema Information
#
# Table name: server_settings
#
#  id             :bigint(8)        not null, primary key
#  name           :string
#  optional_value :string
#  value          :boolean
#  position       :integer
#  parent_id      :bigint(8)
#  deleted_at     :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class ServerSetting < ApplicationRecord
end
