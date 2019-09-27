class ApplicationController < ActionController::Base
  before_action :check_date
  def check_date
    unless Date.today.month == 9
      flash[:info] = "Questi dati non vengono più aggiornati perchè è finito Settembre, rimangono validi. L'aggiornamento finale viene eseguito nel mese di ottobre solo se qualcuno visita la pagina (è stato schedulato e dovrebbe essere eseguito a breve)."
    end
    
    if Date.today.month == 10
      UpdateDataWorker.perform_async
      flash[:info] = "Verrà iniziato l'aggiornamento manuale dei dati. Ricarica questa pagina tra un po'"
    end
  end

end
