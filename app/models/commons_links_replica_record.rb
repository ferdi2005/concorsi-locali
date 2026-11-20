class CommonsLinksReplicaRecord < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :commons_links_replica

  def readonly?
    true
  end
end
