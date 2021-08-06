require "addressable/uri"
class UpdateDataWorker
  include Sidekiq::Worker
  sidekiq_options({
    # Should be set to true (enables uniqueness for async jobs)
    # or :all (enables uniqueness for both async and scheduled jobs)
    unique: :all
  })

  def perform
    Contest.all.each do |contest|
      puts "Ottengo la categoria della regione #{contest.name} (#{contest.category})..."
      
      # Facendo uso del generator categorymembers, ottiene le informazioni sulle foto nella categoria d'elezione 
      commons_api = "https://commons.wikimedia.org/w/api.php"
      request = HTTParty.get(commons_api, query: {action: :query, prop: :imageinfo, iiprop: 'user|timestamp|userid', generator: :categorymembers, gcmtitle: contest.category, gcmdir: :newer, gcmlimit: 500, format: :json}, uri_adapter: Addressable::URI).to_h

      photolist = request["query"]["pages"]

      # Procede con la continuazione
      while !request["continue"].nil?
        request = HTTParty.get(commons_api, query: {action: :query, prop: :imageinfo, iiprop: 'user|timestamp|userid', generator: :categorymembers, gcmtitle: contest.category, gcmdir: :newer, gcmcontinue: request["continue"]["gcmcontinue"], gcmlimit: 500, format: :json}, uri_adapter: Addressable::URI).to_h
        photolist.merge!(request["query"]["pages"]) # Unisce i due hash
      end

      # Rimuove le fotografie che già esistono in memoria o che non sono foto (namespace 6)
      photolist.reject! { |_, photo| Photo.exists?(name: photo['title']) || photo['ns'] != 6 }
      
      photolist.each do |_, photo|
        # Shortcut alle informazioni più proprie dell'immagine
        photoinfo = photo['imageinfo'][0]

        # Procede solo se la fotografia è stata scattata nel periodo di Settembre
        next unless photoinfo['timestamp'].to_date.between?(Date.parse("1 september #{contest.year}"), Date.parse("30 september #{contest.year}"))

        # Verifica la presenza o no di utilizzi della fotografia 
        # (prende il valore contrario poiché con blank si verifica con true l'assenza di utilizzi)

        usedonwiki = !HTTParty.get("https://commons.wikimedia.org/w/api.php", query: {action: :query, prop: :globalusage, pageids:photo['pageid'], gunamespace: 0, format: :json}, uri_adapter: Addressable::URI).to_h["query"]["pages"][photo['pageid'].to_s]["globalusage"].blank?
        
        # Se non c'è l'utente, lo crea, altrimenti lo individua normalmente
        if Creator.exists?(username: photoinfo['user']) || Creator.exists?(userid: photoinfo['userid'])
          creator = Creator.where(username: photoinfo['user']).or(Creator.where(userid: photoinfo['userid'])).first
        else
          # Recupera le informazioni sull'utente da Commons
          userinfo = HTTParty.get("https://commons.wikimedia.org/w/api.php", query: {action: :query, meta: :globaluserinfo, guiuser: photoinfo['user'], format: :json}, uri_adapter: Addressable::URI).to_h["query"]["globaluserinfo"]

          creator = Creator.create(username: photoinfo["user"], userid: photoinfo['userid'], creationdate: userinfo['registration'])

          # Verifica se l'utente si è iscritto appositamente per il concorso
          unless userinfo['registration'].nil?
            creator.update_attribute(:proveniencecontest, contest.id) if userinfo['registration'].to_date == photoinfo['timestamp'].to_date || userinfo['registration'].to_date.between?(Date.parse('30 august'), Date.parse('30 september'))
          end
        end

        @photo = Photo.create(pageid: photo['pageid'], name: photo['title'], creator: creator, contest: contest, photodate: photoinfo['timestamp'], usedonwiki: usedonwiki)
      end
    end

    puts 'Inizio salvataggio del conto dei creatori.'
    Contest.all.each do |contest|
      # Creatori con foto partecipanti
      creators = Creator.includes(:photos).select { |m| m.photos.where(contest: contest).any? }.count
      contest.update_attribute(:creators, creators)
      
      # Utenti iscritti appositamente per il concorso
      creatorsapposta = Creator.where(proveniencecontest: contest.id).count
      contest.update_attribute(:creatorsapposta, creatorsapposta) 
    end
  end
end