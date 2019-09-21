class ApplicationController < ActionController::Base
  unless Date.today.month == 9
    flash[:info] = "Questi dati non vengono più aggiornati perchè è finito Settembre, rimangono validi. L'aggiornamento finale viene eseguito nel mese di ottobre solo se qualcuno visita la pagina (è stato schedulato e dovrebbe essere eseguito a breve)."
  end
  
  if Date.today.month == 10
    UpdateDataJob.perform_later
  end

end
