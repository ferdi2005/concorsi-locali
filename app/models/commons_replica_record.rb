class CommonsReplicaRecord < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :commons_replica

  def readonly?
    true
  end
end
