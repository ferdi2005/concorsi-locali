class CentralAuthReplicaRecord < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :centralauth_replica

  def readonly?
    true
  end
end
