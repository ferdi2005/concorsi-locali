class UpdateNophotoDataWorker
  include Sidekiq::Worker

  def perform(*args)
    nophotodata = HTTParty.get("https://cerca.wikilovesmonuments.it/allregionsdifference.json").to_a
    nophotodata.last(21).each do |nop|
      if nop["regione"].nil?
        Nophoto.create(count: nop["count"], monuments: nop["monuments"], with_commons: nop["with_commons"], with_image: nop["with_image"], nowlm: nop["nowlm"], percent: (nop["count"].to_f / nop["monuments"].to_f * 100).round(2))
      else
        Nophoto.create(count: nop["count"], monuments: nop["monuments"], with_commons: nop["with_commons"], with_image: nop["with_image"], nowlm: nop["nowlm"], regione: nop["regione"], percent: (nop["count"].to_f / nop["monuments"].to_f * 100).round(2))
        
        # Aggiorno anche i dati nella regione
        regione = Contest.find_by(region: nop["regione"])
        regione.update!(nophoto: nop["count"], monuments: nop["monuments"], with_commons: nop["with_commons"], with_image: nop["with_image"], nowlm: nop["nowlm"]) unless regione.nil?
      end
    end
  end
end