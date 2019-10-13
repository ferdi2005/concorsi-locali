require "addressable/uri"
class UpdateDataWorker
  include Sidekiq::Worker
  sidekiq_options({
    # Should be set to true (enables uniqueness for async jobs)
    # or :all (enables uniqueness for both async and scheduled jobs)
    unique: true
  })
  def perform
    start = Time.now
    Contest.all.each do |contest|
      puts "Ottengo la categoria della regione #{contest.name} (#{contest.category})..."
      request_photolist = "https://commons.wikimedia.org/w/api.php"
      photolist = HTTParty.get(request_photolist, query: {action: :query, list: :categorymembers, cmtitle: contest.category, cmlimit: 500, cmdir: :newer, format: :json}, uri_adapter: Addressable::URI).to_a
      if photolist[2].nil?
        photolist = photolist[1][1]['categorymembers']
      else
        cmcontinue = photolist[1][1]['cmcontinue']
        continue = photolist[1][1]['continue']
        photolist = photolist[2][1]['categorymembers']
      end

      unless photolist.nil?
        while continue == '-||'
          puts 'Ottengo la continuazione della categoria...'
          new_request_photolist = "https://commons.wikimedia.org/w/api.php"
          new_photolist = HTTParty.get(new_request_photolist, query: {action: :query, list: :categorymembers, cmtitle: contest.category, cmlimit: 500, cmdir: :newer, cmcontinue: cmcontinue, format: :json }, uri_adapter: Addressable::URI).to_a
          unless new_photolist.nil?
            if new_photolist[2].nil?
              new_photolist = new_photolist[1][1]['categorymembers']
              continue = false
              @noph = true
            else
              cmcontinue = new_photolist[1][1]['cmcontinue']
              continue = new_photolist[1][1]['continue']
              new_photolist = new_photolist[2][1]['categorymembers']
            end      
            unless new_photolist.nil?
              puts 'Sommo le liste di foto...'
              photolist = photolist += new_photolist
            end
          end
        end
        photolist.reject! { |photo| Photo.where(name: photo['title']).count > 0 }
        puts 'Inizio a processare le singole foto...'
          photolist.each do |photo|
            if photo['ns'].to_s == '6'
              photoinfo = HTTParty.get("https://commons.wikimedia.org/w/api.php", query: {action: :query,pageids: photo['pageid'], prop: :imageinfo, iiprop: 'user|timestamp|userid', format: :json}, uri_adapter: Addressable::URI).to_a[1][1]['pages'][photo['pageid'].to_s]['imageinfo'][0] # Looks for photoinfo
                globalusage = HTTParty.get("https://commons.wikimedia.org/w/api.php",query: {action: :query, prop: :globalusage, pageids:photo['pageid'], gunamespace: 0, format: :json}, uri_adapter: Addressable::URI).to_a[1][1]['pages'][photo['pageid'].to_s]['globalusage'].try(:empty?)
                puts "Foto: #{photo['title']} di #{photoinfo['user']}..."
                @userinfo = HTTParty.get("https://commons.wikimedia.org/w/api.php", query: {action: :query, meta: :globaluserinfo, guiuser: photoinfo['user'], format: :json}, uri_adapter: Addressable::URI).to_a[1][1]['globaluserinfo']
                @registration = @userinfo['registration']
                @creationdate = @registration
                @name = photoinfo['user']
                if Creator.where(username: @name).or(Creator.where(username: photoinfo['userid'])).count > 0
                  @creator = Creator.where(username: photoinfo['user']).or(Creator.where(userid: photoinfo['userid'])).first
                else
                    puts "Creo l'utente #{photoinfo['user']}"
                    @creator = Creator.create(username: @name, userid: photoinfo['userid'], creationdate: @creationdate)
                    unless @creationdate.nil?
                      @creator.update_attribute(:proveniencecontest, contest.id) if @creationdate.to_date == photoinfo['timestamp'].to_date || @creationdate.to_date.between?(Date.parse('30/08/2019'), Date.parse('30/09/2019'))  
                    end
                end
                  @photo = Photo.create(pageid: photo['pageid'], name: photo['title'], creator: @creator, contest: contest, photodate: photoinfo['timestamp'], usedonwiki: !globalusage)
              end
                end
      end
    end
    
    puts 'Inizio salvataggio del conto dei creatori.'
      Contest.all.each do |contest|
        @creators = Creator.includes(:photos).select { |m| m.photos.where(contest: contest).any? }.count

        contest.update_attribute(:creators, @creators)
        creatorsapposta = Creator.where(proveniencecontest: contest.id).count
        contest.update_attribute(:creatorsapposta, creatorsapposta) 
      end
      puts 'Tempo di esecuzione'
      puts Time.now - start
  end
end