class ApplicationController < ActionController::Base
  before_action :check_date
  def check_date
    unless Date.today.month == 9
      flash[:info] = "Questi dati non vengono più aggiornati perchè è finito Settembre, rimangono validi. Un aggiornamento viene eseguito nel mese di ottobre qualora qualcuno visiti la pagina."
    end
    
    if Date.today.month == 10
      UpdateDataWorker.perform_async
      flash[:info] = "Verrà iniziato l'aggiornamento manuale dei dati. Ricarica questa pagina tra qualche minuto."
    end
  end

end
