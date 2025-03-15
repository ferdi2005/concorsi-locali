class UpdateNophotoDataWorker
  include Sidekiq::Worker

  def perform(*args)
    @year = Year.find_by_year(Date.today.year)
    nophotodata = HTTParty.get("https://cerca.wikilovesmonuments.it/allregionsdifference.json").to_a
    nophotodata.last(21).each do |nop|
      if nop["regione"].nil?
        Nophoto.create(count: nop["count"], monuments: nop["monuments"], with_commons: nop["with_commons"], with_image: nop["with_image"], nowlm: nop["nowlm"], percent: (nop["count"].to_f / nop["monuments"].to_f * 100).round(2), year: @year)
      else
        Nophoto.create(count: nop["count"], monuments: nop["monuments"], with_commons: nop["with_commons"], with_image: nop["with_image"], nowlm: nop["nowlm"], regione: nop["regione"], percent: (nop["count"].to_f / nop["monuments"].to_f * 100).round(2), year: @year)
        # Aggiorno anche i dati nella regione
        regione = Contest.find_by(region: nop["regione"])
        contestyear = ContestYear.find_by(contest: regione, year: @year)
        contestyear&.update!(nophoto: nop["count"], monuments: nop["monuments"], with_commons: nop["with_commons"], with_image: nop["with_image"], nowlm: nop["nowlm"])
      end
    end
  end
end
