class UpdateNophotoDataWorker
  include Sidekiq::Worker

  def perform(*args)
    nophotodata = HTTParty.get("https://cerca.wikilovesmonuments.it/allregionsdifference.json").to_a
    nophotodata.last(21).each do |nop|
      if nop["regione"].nil?
        Nophoto.create(count: nop["count"], monuments: nop["monuments"], with_commons: nop["with_commons"], with_image: nop["with_image"], nowlm: nop["nowlm"])
      else
        Nophoto.create(count: nop["count"], monuments: nop["monuments"], with_commons: nop["with_commons"], with_image: nop["with_image"], nowlm: nop["nowlm"], regione: nop["regione"])
        regione = Contest.find_by(region: nop["regione"])
        regione.update_attributes(nophoto: nop["count"], monuments: nop["monuments"], with_commons: nop["with_commons"], with_image: nop["with_image"], nowlm: nop["nowlm"]) unless regione.nil?
      end
    end
  end
end