class NumericsController < ApplicationController
    before_action :set_contest

    def totalphotos
        unless @contest == false
            photocount = @contest.count
        else 
            photocount = Photo.count
        end
        json = { 
            'postfix': 'Fotografie totali',
            'data': { 
                "value": photocount
             }
         }
        respond_to do |format|
            format.json { render json: json }
        end
    end

    def todayphotos
        data = []
        unless @contest == false
            photowithdate = @contest.photos.group_by_day(:photodate).count.to_a.last(2).reverse
            photowithdate.each do |ph|
                data.push({'value': ph[1]})
            end
        else 
            photowithdate = Photo.all.group_by_day(:photodate).count.to_a.last(2).reverse
            photowithdate.each do |ph|
                data.push({'value': ph[1]})
            end
        end
        json = { 
            'postfix': 'Fotografie di oggi',
            'data': data
         }
        respond_to do |format|
            format.json { render json: json }
        end
    end

    def totalcreators
        unless @contest == false
            creatorcount = @contest.creators
        else 
            creatorcount = Creator.count
        end
        json = { 
            'postfix': 'Partecipanti',
            'data': { 
                "value": creatorcount
             }
         }
        respond_to do |format|
            format.json { render json: json }
        end
    end

    def totalcreatorsapposta
        unless @contest == false
            creatorcount = @contest.creatorsapposta.to_i
        else
            creatorcount = Creator.where.not(proveniencecontest: nil).count
        end 
            json = { 
                'postfix': 'Partecipanti iscritti per il concorso',
                'data': { 
                    "value": creatorcount
                }
            }
            respond_to do |format|
                format.json { render json: json }
            end
    end

    def todaycreatorsapposta
        data = []
        unless @contest == false
            photowithdate = Creator.where(proveniencecontest: @contest.id).group_by_day(:creationdate).count.to_a.last(2).reverse
            photowithdate.each do |ph|
                data.push({'value': ph[1]})
            end
        else 
            photowithdate = Creator.all.group_by_day(:creationdate).count.to_a.last(2).reverse
            photowithdate.each do |ph|
                data.push({'value': ph[1]})
            end
        end
        json = { 
            'postfix': 'Partecipanti iscritti per il concorso',
            'data': data
         }
        respond_to do |format|
            format.json { render json: json }
        end
    end


    def days
        if Date.today.month == 9
            name = "Fine di WLM"
            date = Date.parse('30 september').strftime("%Y-%m-%d")
        else
            name = "Inizio di WLM"
            date = Date.parse('1 september').strftime("%Y-%m-%d")
        end
        respond_to do |format|
            format.json { render json: {
                "data": {
                    "name": name,
                    "dateValue": date,
                    "dateFormat": "yyyy-MM-dd"
                }
            } }
        end
    end

    def photograph
        hashdata = []
        unless @contest == false
            @contest.photos.group_by_day(:photodate).count.to_a.last(31).each do |pl|
                hashdata.push({"value": pl[1]})
            end
        else
            Photo.all.group_by_day(:photodate).count.to_a.last(31).each do |pl|
                hashdata.push({"value": pl[1]})
            end
        end
        nophoto = { 
            "postfix": "Grafico delle foto caricate",
            "data": hashdata
         }
        respond_to do |format|
            format.json {render json: nophoto }
        end
    end

    def photoday
        hashdata = []
        unless @contest == false
            @contest.photos.group_by_day(:photodate).count.to_a.last(31).each do |pl|
                hashdata.push({"date": pl[0].strftime("%Y-%m-%d"), "value": pl[1]})
            end
        else
            Photo.all.group_by_day(:photodate).count.to_a.last(31).each do |pl|
                hashdata.push({"date": pl[0].strftime("%Y-%m-%d"), "value": pl[1]})
            end
        end
        nophoto = { 
            "postfix": "Densità giornaliera delle foto caricate",
            "data": hashdata
         }
        respond_to do |format|
            format.json {render json: nophoto }
        end
    end

    def usedonwiki
        unless @contest == false
            photocount = @contest.photos.where(usedonwiki: true).count
        else 
            photocount = Photo.where(usedonwiki: true).count
        end
        json = { 
            'postfix': 'Fotografie usate sui progetti',
            'data': { 
                "value": photocount
             }
         }
        respond_to do |format|
            format.json { render json: json }
        end
    end

    def usedonwikipercentage
        unless @contest == false
            photocount = (@contest.photos.where(usedonwiki: true).count.to_f / @contest.count.to_f * 100.0).truncate(1) unless (@contest.photos.where(usedonwiki: true).count.to_f / @contest.count.to_f * 100.0).nan?
            photocount = '0.0' if (@contest.photos.where(usedonwiki: true).count.to_f / @contest.count.to_f * 100.0).nan?
        else 
            photocount = (Photo.where(usedonwiki: true).count.to_f / Photo.all.count.to_f * 100.0).truncate(1) unless (Photo.where(usedonwiki: true).count.to_f / Photo.all.count.to_f * 100.0).nan?
            photocount = '0.0' if (Photo.where(usedonwiki: true).count.to_f / Photo.all.count.to_f * 100.0).nan?
        end
        json = { 
            'postfix': 'Fotografie usate sui progetti',
            'data': { 
                "value": photocount.to_s + "%"
             }
         }
        respond_to do |format|
            format.json { render json: json }
        end
    end


    def photos_relativetogeneral
        unless @contest == false
            value = (@contest.count.to_f / Photo.count.to_f * 100).truncate(1) unless (@contest.count.to_f / Photo.count.to_f * 100.0).nan?
            value = "0" if (@contest.count.to_f / Photo.count.to_f * 100.0).nan?
        else 
            value = "100"
        end
        json = { 
            'postfix': 'Fotografie in relazione al nazionale',
            'data': { 
                "value": value.to_s + "%"
             }
         }
        respond_to do |format|
            format.json { render json: json }
        end
    end

    def participants_relativetogeneral
        unless @contest == false
            value = (@contest.creators.to_f / Creator.count.to_f * 100).truncate(1) unless (@contest.creators.to_f / Creator.count.to_f * 100.0).nan?
            value = "0" if (@contest.creators.to_f / Creator.count.to_f * 100.0).nan?
        else 
            value = "100"
        end
        json = { 
            'postfix': 'Partecipanti in relazione al nazionale',
            'data': { 
                "value": value.to_s + "%"
             }
         }
        respond_to do |format|
            format.json { render json: json }
        end
    end

    def special_photos
        unless @contest == false
            photocount = @contest.fortifications
        else 
            photocount = "0"
        end
        json = { 
            'postfix': "#{ENV["SPECIAL_CATEGORY_LABEL"]}",
            'data': { 
                "value": photocount
             }
         }
        respond_to do |format|
            format.json { render json: json }
        end

    end
    
    def new_monuments
        unless @contest == false
            photocount = @contest.photos.select { |p| p.new_monument == true }.count
        else 
            photocount = Photo.select { |p| p.new_monument == true }.count
        end
        json = { 
            'postfix': "Nuovi monumenti",
            'data': { 
                "value": photocount
             }
         }
        respond_to do |format|
            format.json { render json: json }
        end

    end

    def iscrittiappostapercentage
        unless @contest == false
            photocount = (@contest.creatorsapposta.to_f / @contest.creators.to_f * 100.0).truncate(1) unless (@contest.creatorsapposta.to_f / @contest.creators.to_f * 100.0).nan? || @contest.creatorsapposta == 0 || @contest.creators == 0
            photocount = '0.0' if (@contest.creatorsapposta.to_f / @contest.creators.to_f * 100.0).nan? || @contest.creatorsapposta == 0 || @contest.creators == 0
        else 
            photocount = (Creator.where.not(proveniencecontest: nil).count.to_f / Creator.count.to_f * 100.0).truncate(1) unless (Creator.where.not(proveniencecontest: nil).count.to_f / Creator.count.to_f * 100.0).nan? || Creator.where.not(proveniencecontest: nil).count == 0 || Creator.count == 0
            photocount = '0.0' if (Creator.where.not(proveniencecontest: nil).count.to_f / Creator.count.to_f * 100.0).nan? || Creator.where.not(proveniencecontest: nil).count == 0 || Creator.count == 0
        end
        json = { 
            'postfix': 'Percentuale',
            'data': { 
                "value": photocount.to_s + "%"
             }
         }
        respond_to do |format|
            format.json { render json: json }
        end
    end

    def miglioriutenti
        unless @contest == false
            list = []
            @creators = []
            Creator.all.each do |creator|
              if creator.photos.where(contest: @contest).any?
                @creators.push(creator)
              end
            end
            @creators = @creators.sort_by{|gp| gp.photos.where(contest: @contest).count}.reverse
            @creators.each do |creator|
                list.push({'name': creator.username, 'value': creator.photos.where(contest: @contest).count})
            end
        else
            list = []
            @creators = Creator.all.sort_by{|creator| creator.photos.count}.reverse
            @creators.each do |creator|
                list.push({'name': creator.username, 'value': creator.photos.count})
            end
        end
        json =  { 
            "valueNameHeader": "Partecipanti più prolifici",
            "valueHeader": "Foto",
            "data": list
         }
        respond_to do |format|
            format.json { render json: json }
        end
    end
        
    def iscrittiappostagraph
        hashdata = []
        unless @contest == false
            Creator.where(proveniencecontest: @contest.id).group_by_day(:creationdate).count.to_a.last(31).each do |pl|
                hashdata.push({"value": pl[1]})
            end
        else
            Creator.all.where.not(proveniencecontest: nil).all.group_by_day(:creationdate).count.to_a.last(31).each do |pl|
                hashdata.push({"value": pl[1]})
            end
        end
        nophoto = { 
            "postfix": "Grafico degli utenti iscritti per il concorso",
            "data": hashdata
         }
        respond_to do |format|
            format.json {render json: nophoto }
        end
    end
end
private
def set_contest
    if !params[:id].blank?
        @contest = Contest.find(params[:id])
    else
        @contest = false
    end 
end