require 'active_record'
namespace :db do
  desc "Crea tutti i concorsi locali per l'Italia presenti sul sito alla data del 2 settembre"
  task :concorsi => :environment do
    # Contest(id: integer, category: string, name: string, created_at: datetime, updated_at: datetime, url: string)
    # Puglia
    Contest.create(category: 'Category:Images from Wiki Loves Monuments 2019 in Italy - Apulia', name: 'Wiki Loves Puglia', url: 'https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali/#11')
    puts 'Creating Puglia...'
    # Basilicata
    Contest.create(category: 'Category:Images from Wiki Loves Monuments 2019 in Italy - Basilicata', name: 'Wiki Loves Basilicata', url: 'https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali/#12')
    puts 'Creating Basilicata...'
    # Veneto
    Contest.create(category: 'Category:Images from Wiki Loves Monuments 2019 in Italy - Veneto', name: 'Wiki Loves Veneto',url: 'https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali/#4')
    puts 'Creating Veneto...'
    # Liguria
    Contest.create(category: 'Category:Images from Wiki Loves Monuments 2019 in Italy - Liguria', name: 'Wiki Loves Liguria', url: 'https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali/#6')
    puts 'Creating Liguria...'
    # Toscana
    Contest.create(category: 'Category:Images from Wiki Loves Monuments 2019 in Italy - Tuscany', name: 'Wiki Loves Toscana', url: 'https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali/#7')
    puts 'Creating Toscana...'
    # Umbria
    Contest.create(category: 'Category:Images from Wiki Loves Monuments 2019 in Italy - Umbria', name: 'Wiki Loves Umbria', url: 'https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali/#8')
    puts 'Creating Umbria...'
    # Lazio
    Contest.create(category: 'Category:Images from Wiki Loves Monuments 2019 in Italy - Lazio', name: 'Wiki Loves Lazio', url: 'https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali/#9')
    puts 'Creating Lazio...'
    # Abruzzo
    Contest.create(category: 'Category:Images from Wiki Loves Monuments 2019 in Italy - Abruzzo', name: 'Wiki Loves Lazio', url: 'https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali/#10')
    puts 'Creating Abruzzo...'
    puts 'Done'

  end
end
