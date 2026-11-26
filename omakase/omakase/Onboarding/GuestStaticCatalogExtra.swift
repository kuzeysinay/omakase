//
//  GuestStaticCatalogExtra.swift
//  omakase
//
//  12 additional curated, primary-sourced stories in all 7 languages so the
//  pre-login guest tasting pool offers 20 varied stories with zero consecutive repeats.
//

import Foundation

extension GuestStaticPost {

    static func extraPosts(for language: AppLanguage) -> [GuestStaticPost] {
        switch language {
        case .turkish: return extraTurkishPosts
        case .japanese: return extraJapanesePosts
        case .german: return extraGermanPosts
        case .french: return extraFrenchPosts
        case .spanish: return extraSpanishPosts
        case .korean: return extraKoreanPosts
        case .english: return extraEnglishPosts
        }
    }

    // MARK: - English (12 Extra Stories)

    private static let extraEnglishPosts: [GuestStaticPost] = [
        GuestStaticPost(
            id: "cleopatra-iphone",
            categoryId: "history",
            title: "Cleopatra Lived Closer to the iPhone Than to the Great Pyramid",
            tags: ["History", "Timelines", "Egypt"],
            bodyWithSource: """
            The Great Pyramid of Giza was built around **2560 BCE**. Cleopatra VII was born in **69 BCE**—nearly *2,500 years* after the stones were stacked.

            Between Cleopatra and the 2007 iPhone launch sit only **2,076 years**, making Ancient Rome's most famous queen chronologically closer to smartphones than to Giza's builders.

            Source: Joyce Tyldesley, Cleopatra: Last Queen of Egypt (2008)
            """,
            deepDiveWithSource: """
            Ancient Egypt spans more than three millennia, yet pop culture compresses it into one monochrome tableau of pyramids and pharaohs. By the time Julius Caesar sailed into Alexandria, the Great Pyramid was already older to Cleopatra than Caesar is to us today.

            Roman tourists actually etched graffiti onto the Sphinx and temples around Giza, marveling at monuments whose original builders had vanished two thousand years earlier.

            Source: Toby Wilkinson, The Rise and Fall of Ancient Egypt (2010)
            """
        ),
        GuestStaticPost(
            id: "eiffel-summer-growth",
            categoryId: "science",
            title: "Why the Eiffel Tower Grows 15 Centimeters Every Summer",
            tags: ["Science", "Architecture", "Paris"],
            bodyWithSource: """
            Gustave Eiffel's wrought-iron lattice weighs 7,300 tons and isn't rigid at all—it breathes with Paris weather.

            On hot July afternoons, **thermal expansion** stretches its puddle-iron girders until the entire monument stands up to **15 centimeters taller** and subtly tilts away from the sun.

            Source: SETE — Société d'Exploitation de la Tour Eiffel Archives
            """,
            deepDiveWithSource: """
            Wrought iron expands linearly by about 12 micrometers per meter for every degree Celsius of warming. Across a 300-meter structure bathed in 40°C summer sun versus freezing January winds, the math adds up to nearly six inches of vertical stretch.

            Because the sun heats only the sunlit side of the tower at a time, the iron on that face expands faster, bending the summit away from the sun in a slow daily oval of up to 18 centimeters.

            Source: Gustave Eiffel, La Tour de Trois Cents Mètres (1900)
            """
        ),
        GuestStaticPost(
            id: "napoleon-rabbits",
            categoryId: "history",
            title: "The Day Napoleon Was Chased Off the Field by Rabbits",
            tags: ["History", "Weird History", "France"],
            bodyWithSource: """
            After signing the Treaties of Tilsit in **1807**, Napoleon celebrated with a rabbit hunt organized by his chief of staff—who accidentally bought hundreds of *tame farm rabbits* instead of wild hares.

            When the cages opened, the rabbits recognized Napoleon as food-giver-in-chief and charged in a furry swarm, climbing his coat until the Emperor retreated to his carriage.

            Source: David Chandler, The Campaigns of Napoleon (1966)
            """,
            deepDiveWithSource: """
            Marshal Alexandre Berthier wanted to impress France's victorious generals, so his aides collected every rabbit they could find across nearby farms—possibly up to a thousand animals raised in hutches.

            Unfazed by hunting horns or boots, the hungry rabbits split into two flanking wings and swarmed Napoleon's legs faster than whip-cracking beaters could shoo them away. Eyewitnesses recorded the generals bursting into laughter while coachmen whipped the horses clear of the bunny ambush.

            Source: Memoirs of Baron Thiébault (1896)
            """
        ),
        GuestStaticPost(
            id: "hitchcock-psycho-syrup",
            categoryId: "film",
            title: "Why Psycho's Famous Shower Scene Used Chocolate Syrup",
            tags: ["Cinema", "Directing", "Craft"],
            bodyWithSource: """
            Alfred Hitchcock shot *Psycho* (1960) on a tight TV-crew budget in stark black-and-white—partially to keep censors from banning the gore.

            Fake red stage blood looked muddy on monochrome film, so props mixed **Bosco chocolate syrup**, which had the exact *viscous sheen* and deep charcoal tone needed swirling down the drain.

            Source: Stephen Rebello, Alfred Hitchcock and the Making of Psycho (1990)
            """,
            deepDiveWithSource: """
            Hitchcock spent seven days filming 78 camera setups and 52 rapid cuts for just 45 seconds of screen time, ensuring no single shot ever showed knife touching skin.

            Because studio panchromatic film rendered bright red far too pale and watery, Bosco's dark caramel-brown thickness read unmistakably as fresh blood under harsh white tiles—while also keeping actors sticky between takes under hot studio lamps.

            Source: Janet Leigh & Christopher Nickens, Psycho: Behind the Scenes of the Classic Thriller (1995)
            """
        ),
        GuestStaticPost(
            id: "venus-day-year",
            categoryId: "science",
            title: "On Venus, a Single Day Lasts Longer Than an Entire Year",
            tags: ["Science", "Astronomy", "Space"],
            bodyWithSource: """
            Venus orbits the Sun every **224.7 Earth days**, yet it spins backward on its axis at a glacial crawl taking **243 Earth days** to complete one full rotation.

            Wait on Venus for noon-to-noon—called a solar day—and you'll still see the Sun rise in the **west** and crawl across the sulfuric sky.

            Source: NASA Jet Propulsion Laboratory — Planetary Fact Sheet
            """,
            deepDiveWithSource: """
            Astronomers distinguish between a planet's *sidereal day* (243 Earth days against background stars) and its *solar day* (noon to noon, which on Venus equals 116.75 Earth days because its retrograde spin fights its orbital motion).

            Even stranger: dense atmospheric tides driven by solar heating actually tug Venus's rotation rate slightly faster or slower over decades—measured cleanly only when radar peers through its permanent clouds.

            Source: Jean-Luc Margot et al., Nature Astronomy (2021)
            """
        ),
        GuestStaticPost(
            id: "volcano-bicycle",
            categoryId: "history",
            title: "How a Volcanic Eruption Led to the Invention of the Bicycle",
            tags: ["History", "Design", "Climate"],
            bodyWithSource: """
            When Indonesia's **Mount Tambora** erupted in 1815, ash veiled the globe and triggered 1816's *Year Without a Summer*. Crops failed across Europe, and oats grew so scarce horses starved.

            Seeking horse-free transport in 1817, German inventor Karl Drais built the wooden two-wheeled **Laufmaschine**—the direct ancestor of the modern bicycle.

            Source: Gillen D'Arcy Wood, Tambora: The Eruption That Changed the World (2014)
            """,
            deepDiveWithSource: """
            Drais debuted his steerable running machine in Mannheim by covering 13 kilometers in under an hour—faster than post coaches plodding over rutted roads. Riders pushed off with their feet and coasted along footpaths.

            Though pedals wouldn't arrive for another forty years, Drais's inline two-wheel geometry solved balance through steering—a breakthrough born directly from famine-driven necessity.

            Source: Hans-Erhard Lessing, Automobilität: Karl Drais und die unglaublichen Anfänge (2003)
            """
        ),
        GuestStaticPost(
            id: "babylon-copper-complaint",
            categoryId: "history",
            title: "The Oldest Known Customer Complaint Is 3,750 Years Old",
            tags: ["History", "Mesopotamia", "Culture"],
            bodyWithSource: """
            In **1750 BCE**, an angry Mesopotamian buyer named Nanni carved a furious clay tablet to copper merchant **Ea-nasir** in Ur, complaining the ingots he delivered were subpar—and that Ea-nasir treated his messenger with contempt.

            Archaeologists unearthed Nanni's tablet *inside Ea-nasir's own house*, filed alongside dozens of other furious buyer complaints.

            Source: British Museum Collection, Object U.16800 (Ur Excavations)
            """,
            deepDiveWithSource: """
            Written in Akkadian cuneiform on a palm-sized clay wedge, Nanni asks: *"What do you take me for, that you treat somebody like me with such contempt?"* before demanding his money back intact.

            Sir Leonard Woolley's 1920s dig revealed Ea-nasir kept an entire archive of angry notes from cheated partners—turning an ancient Bronze Age wholesaler into the internet's favorite patron saint of one-star reviews.

            Source: A. Leo Oppenheim, Letters from Mesopotamia (1967)
            """
        ),
        GuestStaticPost(
            id: "nintendo-1889",
            categoryId: "history",
            title: "Nintendo Was Founded the Same Year the Eiffel Tower Opened",
            tags: ["History", "Gaming", "Japan"],
            bodyWithSource: """
            Long before Mario or Switch consoles, Fusajiro Yamauchi opened **Nintendo Koppai** in Kyoto in **September 1889**—literally weeks after Paris unveiled the Eiffel Tower and the Ottoman Empire still stood.

            For over seventy years, the company survived painting traditional *hanafuda* flower cards by hand on mulberry bark.

            Source: Florent Gorges, The History of Nintendo 1889–1980 (2012)
            """,
            deepDiveWithSource: """
            Because numbered playing cards were restricted in Meiji Japan due to gambling laws, illustrated seasonal hanafuda decks slipped past bans and became an underground hit in Kyoto parlors.

            When grandson Hiroshi Yamauchi took over in 1949, he steered the card workshop toward Disney plastic decks, love hotels, taxi fleets, and ultra-short electronic toys—before Gunpei Yokoi's Game & Watch finally ignited Nintendo's arcade era.

            Source: David Sheff, Game Over (1993)
            """
        ),
        GuestStaticPost(
            id: "sharks-older-than-trees",
            categoryId: "science",
            title: "Sharks Are Older Than Both Trees and Saturn's Rings",
            tags: ["Science", "Nature", "Timelines"],
            bodyWithSource: """
            Fossil shark scales date back roughly **450 million years** to the Ordovician seas—around *90 million years before* the first woody trees took root on land during the Devonian.

            Even wilder: Cassini data suggests Saturn's icy rings may be just **10 to 100 million years** old, making sharks *four times older* than Saturn's signature halo.

            Source: Luciano Iess et al., Science (2019) & Ivanov et al., Paleobiology
            """,
            deepDiveWithSource: """
            Sharks have survived all five of Earth's Big Five mass extinctions—including the Permian-Triassic "Great Dying" that wiped out over 80 percent of marine species 252 million years ago.

            Meanwhile, gravity measurements from Cassini's final orbits showed Saturn's bright rings contain less mass and far less cosmic dust darkening than ancient rings should carry, pointing to a relatively recent shattered moon or comet capture.

            Source: Sascha Kempf et al., Science Advances (2023)
            """
        ),
        GuestStaticPost(
            id: "mario-mustache-pixels",
            categoryId: "design",
            title: "Why Mario Has a Hat, Overalls, and a Mustache",
            tags: ["Design", "Gaming", "Craft"],
            bodyWithSource: """
            Designing *Donkey Kong* in **1981**, Shigeru Miyamoto had only a **16×16 pixel grid** and three colors per sprite on arcade hardware.

            He gave Mario a **cap** because animating hair was impossible, **red overalls** so arm swings stood out against his torso, and a **mustache** so players could spot where his nose ended without needing a mouth.

            Source: Shigeru Miyamoto, Iwata Asks: New Super Mario Bros. Wii (2009)
            """,
            deepDiveWithSource: """
            Arcade CRTs blurred adjacent pixels on low-resolution phosphor screens, so subtle facial features vanished into mud at frame rates of 60 Hz. By turning hardware constraints into bold silhouettes—cap, nose, thick mustache, bright overalls—Miyamoto made an instant icon readable from across a smoky arcade room.

            Every timeless character constraint in 8-bit history traces back to those 256 tiny glowing squares.

            Source: Chris Kohler, Power-Up: How Japanese Video Games Gave the World an Extra Life (2004)
            """
        ),
        GuestStaticPost(
            id: "pigeons-monet-picasso",
            categoryId: "science",
            title: "Scientists Taught Pigeons to Tell Monet Apart From Picasso",
            tags: ["Science", "Art", "Psychology"],
            bodyWithSource: """
            In **1995**, Keio University psychologist Shigeru Watanabe trained pigeons with hemp-seed rewards to peck in response to **Monet** paintings versus **Picasso** cubist works.

            Even when shown *brand-new paintings* they had never seen before—or upside-down and grayscale prints—the birds classified Impressionism from Cubism with over **90% accuracy**, earning Watanabe an Ig Nobel Prize.

            Source: Shigeru Watanabe et al., Journal of the Experimental Analysis of Behavior (1995)
            """,
            deepDiveWithSource: """
            Critics assumed the birds memorized tiny pixel blotches in single images, so researchers deliberately tested generalization: Monet-trained birds immediately recognized Cézanne and Renoir, while Picasso-trained pigeons grouped Braque and Matisse cleanly.

            Pigeons boast tetrachromatic color vision and exceptional pattern integration—proving abstract visual categorization isn't uniquely human.

            Source: Shigeru Watanabe, Animal Cognition (2001)
            """
        ),
        GuestStaticPost(
            id: "chess-more-than-atoms",
            categoryId: "science",
            title: "There Are More Possible Chess Games Than Atoms in the Universe",
            tags: ["Science", "Math", "Culture"],
            bodyWithSource: """
            In 1950, information theory pioneer **Claude Shannon** calculated a conservative lower bound for legal chess variations: **10¹²⁰ games**—now called the *Shannon Number*.

            Astrophysicists estimate the entire observable universe holds around **10⁸⁰ atoms**—meaning after just a few opening moves, chess branches surpass every particle in visible space.

            Source: Claude E. Shannon, Philosophical Magazine (1950)
            """,
            deepDiveWithSource: """
            After white's first move and black's reply, 400 positions exist. After two moves each, 197,742; after three moves each, over 121 million paths open up. Shannon used an average game length of 40 moves with roughly 30 legal replies per ply to derive (10³)^40 = 10¹²⁰.

            Modern enumerations estimate true legal positions on an 8×8 board exceed 10⁴⁴, while distinct game trees stretch orders of magnitude higher still.

            Source: John Tromp & Stefan Edelkamp, Chess Game Complexity (2022)
            """
        )
    ]

    // MARK: - Turkish (12 Extra Stories)

    private static let extraTurkishPosts: [GuestStaticPost] = [
        GuestStaticPost(
            id: "cleopatra-iphone",
            categoryId: "history",
            title: "Kleopatra, Büyük Piramit’ten Çok iPhone’a Daha Yakındı",
            tags: ["Tarih", "Zaman Çizelgesi", "Mısır"],
            bodyWithSource: """
            Giza’daki Büyük Piramit MÖ **2560** civarında tamamlandı. VII. Kleopatra ise MÖ **69**’da doğdu; yani taşlar üst üste konduktan yaklaşık *2.500 yıl sonra*.

            Kleopatra ile 2007’de tanıtılan ilk iPhone arasında sadece **2.076 yıl** var. Antik Mısır’ın son kraliçesi, piramitlerin inşasından çok akıllı telefon çağına daha yakındı.

            Kaynak: Joyce Tyldesley, Cleopatra: Last Queen of Egypt (2008)
            """,
            deepDiveWithSource: """
            Antik Mısır tarihi üç bin yıldan uzun bir döneme yayıldığı için hafızamız tüm o dönemi tek bir sahne gibi sıkıştırır. Oysa Julius Caesar İskenderiye’ye ayak bastığında Büyük Piramit, Kleopatra için bile bugün Sezar’ın bize olduğundan daha eskiydi.

            Romalı gezginler Giza’yı gezip Sfenks ve tapınakların üzerine turist yazıtları kazırken, o anıtları yapan uygarlık çoktan iki bin yıllık bir mazi olmuştu.

            Kaynak: Toby Wilkinson, The Rise and Fall of Ancient Egypt (2010)
            """
        ),
        GuestStaticPost(
            id: "eiffel-summer-growth",
            categoryId: "science",
            title: "Eyfel Kulesi Her Yaz Neden 15 Santimetre Uzar?",
            tags: ["Bilim", "Mimari", "Paris"],
            bodyWithSource: """
            Gustave Eiffel’in 7.300 tonluk dövme demir kafesi sanıldığı gibi sabit durmaz; Paris havasıyla birlikte adeta nefes alır.

            Kavurucu temmuz öğleden sonralarında **termal genleşme** demir kirişleri uzatır; kule yazın **15 santimetreye kadar yükselir** ve tepesi güneşten ters yöne hafifçe eğilir.

            Kaynak: SETE — Société d'Exploitation de la Tour Eiffel Arşivi
            """,
            deepDiveWithSource: """
            Dövme demir her 1°C sıcaklık artışında metre başına yaklaşık 12 mikrometre genleşir. Kışın dondurucu ocak rüzgarlarıyla 40°C’yi bulan yaz güneşi arasındaki fark, 300 metrelik gövdede yaklaşık 15 santimetrelik boy değişimi yaratır.

            Güneş kulenin yalnızca bir yüzünü ısıttığı için ısınan taraf daha hızlı uzar; sonuçta kulenin zirvesi gün içinde güneşin aksi yönüne doğru 18 santimetreye varan yavaş bir oval çizer.

            Kaynak: Gustave Eiffel, La Tour de Trois Cents Mètres (1900)
            """
        ),
        GuestStaticPost(
            id: "napoleon-rabbits",
            categoryId: "history",
            title: "Napolyon’un Tavşan Ordusuna Yenildiği Gün",
            tags: ["Tarih", "İlginç Olaylar", "Fransa"],
            bodyWithSource: """
            1807’de Tilsit Antlaşması’nı kutlamak isteyen Napolyon için kurmay başkanı büyük bir tavşan avı düzenledi; ancak yabani tavşan yerine yanlışlıkla yüzlerce *evcil çiftlik tavşanı* toplattı.

            Kafesler açılınca avdan korkmak yerine Napolyon’u yem getiren kişi sanan tavşanlar tüylü bir sel gibi üzerine koşup paltosuna tırmandı; İmparator arabasına kaçmak zorunda kaldı.

            Kaynak: David Chandler, The Campaigns of Napoleon (1966)
            """,
            deepDiveWithSource: """
            Mareşal Alexandre Berthier zafer sarhoşu komutanlara görkemli bir av sunmak için çevredeki çiftliklerden yüzlerce—bazı kayıtlara göre bine yakın—kafes tavşanı satın aldırdı.

            Av borularından hiç ürkmeyen aç tavşanlar iki kanattan hücuma kalkıp Napolyon’un çizmelerine saldırdı. Kırbaçla dağıtmaya çalışan görevliler yetişemeyince generaller kahkahaya boğuldu, arabacı atları sürüp İmparator’u tavşan kuşatmasından kurtardı.

            Kaynak: Memoirs of Baron Thiébault (1896)
            """
        ),
        GuestStaticPost(
            id: "hitchcock-psycho-syrup",
            categoryId: "film",
            title: "Sapık’ın Duş Sahnesinde Neden Çikolata Sosu Kullanıldı?",
            tags: ["Sinema", "Yönetmenlik", "Zanaat"],
            bodyWithSource: """
            Alfred Hitchcock 1960 tarihli *Sapık*’ı (*Psycho*) TV ekibiyle düşük bütçede ve siyah-beyaz çekti; kısmen sansür kurulunun renkli kan görüntüsünü yasaklamasını önlemek için.

            Kırmızı sahne kanı siyah-beyaz filmde soluk ve çamurlu göründüğü için dekor ekibi **Bosco çikolata şurubu** kullandı; hem *akışkan yoğunluğu* hem koyu tonu gider deliğine akarken kusursuz duruyordu.

            Kaynak: Stephen Rebello, Alfred Hitchcock and the Making of Psycho (1990)
            """,
            deepDiveWithSource: """
            Hitchcock sadece 45 saniyelik sahneyi çekmek için 7 gün harcadı; 78 kamera kurulumu ve 52 hızlı kesmeyle bıçağın tene değdiği tek bir kare bile göstermeden dehşet hissi yarattı.

            Pankromatik siyah-beyaz film kırmızıyı fazla açık griye çeviriyordu. Bosco şurubu ise beyaz fayansların altında koyu parlaklığıyla gerçek kan etkisi verdi; üstelik stüdyo ışıkları altında oyuncuları yapış yapış bıraksa da.

            Kaynak: Janet Leigh & Christopher Nickens, Psycho: Behind the Scenes (1995)
            """
        ),
        GuestStaticPost(
            id: "venus-day-year",
            categoryId: "science",
            title: "Venüs’te Bir Gün, Koca Bir Yıldan Daha Uzundur",
            tags: ["Bilim", "Astronomi", "Uzay"],
            bodyWithSource: """
            Venüs Güneş’in etrafındaki tam turunu **224,7 Dünya gününde** tamamlar; fakat kendi ekseni etrafında ters yöne o kadar yavaş döner ki tek bir tam dönüşü **243 Dünya günü** sürer.

            Bulutların altında öğle vaktini bekleseniz bile Güneş’in doğudan değil **batıdan** doğup ağır ağır gökyüzünü geçtiğini görürsünüz.

            Kaynak: NASA Jet Propulsion Laboratory — Planetary Fact Sheet
            """,
            deepDiveWithSource: """
            Gökbilimciler yıldızlara göre dönüş (*yıldız günü*: 243 Dünya günü) ile öğleden öğleye geçen süre (*güneş günü*: yaklaşık 116,75 Dünya günü) arasında ayrım yapar; ters dönüş yüzünden Venüs’ün güneş günü yörünge hızıyla birleşir.

            Daha şaşırtıcısı, kalın sülfürik asit atmosferindeki dev termal gelgitler gezegenin dönüş hızını on yıllar içinde birkaç dakika hızlandırıp yavaşlatabiliyor.

            Kaynak: Jean-Luc Margot ve ark., Nature Astronomy (2021)
            """
        ),
        GuestStaticPost(
            id: "volcano-bicycle",
            categoryId: "history",
            title: "Bisikletin İcadını Tetikleyen Yanardağ Patlaması",
            tags: ["Tarih", "Tasarım", "İklim"],
            bodyWithSource: """
            1815’te Endonezya’daki **Tambora Yanardağı** patlayınca atmosfere yayılan kül 1816’yı *Yazsız Yıl* yaptı. Avrupa’da ekinler dondu, yulaf kıtlığından binlerce at aç kaldı.

            Atsız ulaşım arayan Alman mucit Karl Drais, 1817’de ayaklarla itilerek sürülen iki tekerlekli ahşap **Laufmaschine**’i tanıttı—modern bisikletin doğrudan atası.

            Kaynak: Gillen D'Arcy Wood, Tambora: The Eruption That Changed the World (2014)
            """,
            deepDiveWithSource: """
            Drais, Mannheim’daki ilk gösterisinde 13 kilometrelik yolu bir saatin altında kat ederek posta arabalarını geride bıraktı. Pedallar henüz icat edilmemişti; sürücüler ayaklarıyla yeri itip gidonla denge kurarak kayıyordu.

            Pedal mekanizması ancak kırk yıl sonra eklendi ama iki tekerleği tek çizgide dengede tutma devrimi doğrudan o büyük iklim kıtlığının zorlamasıyla doğdu.

            Kaynak: Hans-Erhard Lessing, Automobilität: Karl Drais (2003)
            """
        ),
        GuestStaticPost(
            id: "babylon-copper-complaint",
            categoryId: "history",
            title: "Tarihin Bilinen En Eski Müşteri Şikayeti 3.750 Yaşında",
            tags: ["Tarih", "Mezopotamya", "Kültür"],
            bodyWithSource: """
            MÖ **1750** civarında Ur kentinde Nanni adlı öfkeli bir müşteri, bakır tüccarı **Ea-nasir**’e kil tablete kazınmış sert bir şikayet mektubu gönderdi: teslim ettiği külçeler kalitesizdi ve elçisine saygısızlık yapılmıştı.

            Arkeologlar Nanni’nin bu tabletini *bizzat Ea-nasir’in kendi evinde*, başka öfkeli müşterilerin şikayetleriyle birlikte arşivlenmiş halde buldu.

            Kaynak: British Museum Koleksiyonu, Envanter U.16800 (Ur Kazıları)
            """,
            deepDiveWithSource: """
            Akadca çivi yazısıyla avuç içi büyüklüğünde bir kile yazılan mektupta Nanni, *"Beni ne sanıyorsun ki benim gibi birine böyle saygısızca davranıyorsun?"* diye çıkışıp ödediği gümüşü geri ister.

            Sir Leonard Woolley’nin 1920’lerdeki kazılarında Ea-nasir’in evinden başka dolandırılmış tüccarların da sitem tabletleri çıktı; böylece Tunç Çağı toptancısı internet çağının tek yıldızlı yorum simgesine dönüştü.

            Kaynak: A. Leo Oppenheim, Letters from Mesopotamia (1967)
            """
        ),
        GuestStaticPost(
            id: "nintendo-1889",
            categoryId: "history",
            title: "Nintendo, Eyfel Kulesi Açıldığı Yıl Kurulmuştu",
            tags: ["Tarih", "Oyun", "Japonya"],
            bodyWithSource: """
            Mario’dan ya da Switch konsollarından çok önce, Fusajiro Yamauchi **Eylül 1889**’da Kyoto’da **Nintendo Koppai** atölyesini açtı—Paris’te Eyfel Kulesi henüz açılmış, Osmanlı Devleti hâlâ ayaktaydı.

            Şirket yetmiş yılı aşkın süre boyunca dut ağacı kabuğundan elde boyanan geleneksel *hanafuda* çiçek oyun kartları üreterek ayakta kaldı.

            Kaynak: Florent Gorges, The History of Nintendo 1889–1980 (2012)
            """,
            deepDiveWithSource: """
            Meiji dönemi Japonyası’nda kumar yasakları nedeniyle numaralı oyun kartları sıkı denetim altındaydı; mevsim çiçeklerini resmeden hanafuda desteleri ise yasakların etrafından dolaşarak Kyoto’da büyük ilgi gördü.

            1949’da torun Hiroshi Yamauchi şirketi devralınca plastik Disney kartlarından taksi filosuna ve oyuncaklara kadar pek çok alanda denemeler yaptı; ardından Gunpei Yokoi’nin Game & Watch fikri Nintendo’nun dijital çağını başlattı.

            Kaynak: David Sheff, Game Over (1993)
            """
        ),
        GuestStaticPost(
            id: "sharks-older-than-trees",
            categoryId: "science",
            title: "Köpekbalıkları Hem Ağaçlardan Hem Satürn’ün Halkalarından Yaşlıdır",
            tags: ["Bilim", "Doğa", "Zaman Çizelgesi"],
            bodyWithSource: """
            Fosil köpekbalığı pulları yaklaşık **450 milyon yıl** öncesine, Ordovisiyen denizlerine uzanır; yani karalarda ilk odunsu ağaçların kök salmasından yaklaşık *90 milyon yıl önceye*.

            Cassini verileri ise Satürn’ün buzlu halkalarının sadece **10 ila 100 milyon yaşında** olabileceğini gösteriyor; köpekbalıkları o halkalardan bile en az *dört kat* daha eski.

            Kaynak: Luciano Iess ve ark., Science (2019) & Ivanov ve ark., Paleobiology
            """,
            deepDiveWithSource: """
            Köpekbalıkları Dünya’daki beş büyük kitlesel yok oluşun tamamından—252 milyon yıl önce deniz türlerinin yüzde 80’inden fazlasını silen Büyük Yok Oluş dahil—sağ çıkmayı başardı.

            Cassini uzay aracının son yörüngelerindeki kütle çekimi ölçümleri ise Satürn’ün parlak halkalarının beklenenden az toz kirlenmesine sahip olduğunu ortaya koyarak kozmik ölçekte çok genç olduklarını gösterdi.

            Kaynak: Sascha Kempf ve ark., Science Advances (2023)
            """
        ),
        GuestStaticPost(
            id: "mario-mustache-pixels",
            categoryId: "design",
            title: "Mario’nun Şapkası, Tulumu ve Bıyığı Neden Var?",
            tags: ["Tasarım", "Oyun", "Zanaat"],
            bodyWithSource: """
            Shigeru Miyamoto **1981**’de *Donkey Kong*’u tasarlarken elinde karakter başına yalnızca **16×16 piksellik** bir ızgara ve üç renk vardı.

            Saç animasyonu imkansız olduğu için **şapka**, kolların gövdeden seçilmesi için **kırmızı tulum**, ağız çizmeden burnunun bittiği yeri belli etmek için de kalın bir **bıyık** ekledi.

            Kaynak: Shigeru Miyamoto, Iwata Asks: New Super Mario Bros. Wii (2009)
            """,
            deepDiveWithSource: """
            Eski CRT atari monitörleri düşük çözünürlüklü pikselleri hafifçe bulanıklaştırdığı için ince yüz hatları hareket halinde dağılıyordu. Miyamoto donanım kısıtını keskin bir siluete dönüştürdü: şapka, iri burun, bıyık ve kontrast tulum.

            Oyun tarihinin en ikonik karakter tasarımı, aslında 256 küçücük piksel karesinin dayattığı yaratıcı çözümden doğdu.

            Kaynak: Chris Kohler, Power-Up (2004)
            """
        ),
        GuestStaticPost(
            id: "pigeons-monet-picasso",
            categoryId: "science",
            title: "Güvercinlere Monet ile Picasso’yu Ayırt Etmeyi Öğreten Deney",
            tags: ["Bilim", "Sanat", "Psikoloji"],
            bodyWithSource: """
            **1995** yılında Keio Üniversitesi’nden psikolog Shigeru Watanabe, güvercinleri yem ödülleriyle **Monet** ve **Picasso** tablolarını ayıracak şekilde eğitti.

            Kuşlar daha önce *hiç görmedikleri* yeni eserlerde—hatta baş aşağı ve siyah-beyaz baskılarda bile—Empresyonizmi Kübizmden **%90’ın üzerinde** doğrulukla ayırdı ve araştırmaya Ig Nobel Ödülü kazandırdı.

            Kaynak: Shigeru Watanabe ve ark., Journal of the Experimental Analysis of Behavior (1995)
            """,
            deepDiveWithSource: """
            Eleştirmenler kuşların tek tek resimleri ezberlediğini düşününce ekip genelleme testi yaptı: Monet için eğitilen güvercinler Cézanne ve Renoir’ı tanıdı; Picasso grubuysa Braque ile Matisse’i doğru kategorize etti.

            Dört renk konisine sahip kuş görüsü, soyut üslup sınıflandırmasının sadece insana özgü olmadığını kanıtladı.

            Kaynak: Shigeru Watanabe, Animal Cognition (2001)
            """
        ),
        GuestStaticPost(
            id: "chess-more-than-atoms",
            categoryId: "science",
            title: "Satrançta Evrendeki Atomlardan Fazla Olası Oyun Var",
            tags: ["Bilim", "Matematik", "Kültür"],
            bodyWithSource: """
            Bilgi kuramının kurucusu **Claude Shannon**, 1950’de yasal satranç varyasyonları için muhafazakar bir alt sınır hesapladı: **10¹²⁰ olası oyun** (*Shannon Sayısı*).

            Astrofizikçiler gözlemlenebilir evrendeki toplam atom sayısını yaklaşık **10⁸⁰** olarak tahmin ediyor; yani ilk birkaç hamleden sonra tahtadaki olasılıklar evrendeki her parçacığı geride bırakıyor.

            Kaynak: Claude E. Shannon, Philosophical Magazine (1950)
            """,
            deepDiveWithSource: """
            Beyaz ve siyah birer hamle yaptığında 400 konum oluşur; ikişer hamlede 197.742, üçer hamlede ise 121 milyonu aşan yol açılır. Shannon ortalama 40 hamlelik bir oyunda hamle başına yaklaşık 30 seçenek üzerinden (10³)^40 = 10¹²⁰ değerine ulaştı.

            Modern bilgisayar hesaplamaları 8×8 tahtadaki erişilebilir geçerli konumların bile 10⁴⁴’ü aştığını doğruluyor.

            Kaynak: John Tromp & Stefan Edelkamp, Chess Game Complexity (2022)
            """
        )
    ]

    // MARK: - German (12 Extra Stories)

    private static let extraGermanPosts: [GuestStaticPost] = [
        GuestStaticPost(
            id: "cleopatra-iphone",
            categoryId: "history",
            title: "Kleopatra lebte dem iPhone näher als der Cheops-Pyramide",
            tags: ["Geschichte", "Zeitlinie", "Ägypten"],
            bodyWithSource: """
            Die Große Pyramide von Gizeh entstand um **2560 v. Chr.** Kleopatra VII. wurde **69 v. Chr.** geboren – fast *2.500 Jahre* nach dem Bau der Steinwunder.

            Zwischen Kleopatra und dem ersten iPhone 2007 liegen nur **2.076 Jahre**. Damit war sie unserer Smartphone-Ära zeitlich näher als den Erbauern von Gizeh.

            Quelle: Joyce Tyldesley, Cleopatra: Last Queen of Egypt (2008)
            """,
            deepDiveWithSource: """
            Das Alte Ägypten erstreckt sich über mehr als drei Jahrtausende. Als Julius Caesar nach Alexandria segelte, war die Cheops-Pyramide für Kleopatra bereits älter als Caesar für uns heute.

            Römische Reisende ritzten damals sogar Touristen-Graffiti in Denkmäler, deren Baumeister schon seit zwei Jahrtausenden Geschichte waren.

            Quelle: Toby Wilkinson, The Rise and Fall of Ancient Egypt (2010)
            """
        ),
        GuestStaticPost(
            id: "eiffel-summer-growth",
            categoryId: "science",
            title: "Warum der Eiffelturm im Sommer um 15 Zentimeter wächst",
            tags: ["Wissenschaft", "Architektur", "Paris"],
            bodyWithSource: """
            Gustave Eiffels 7.300 Tonnen schweres Eisengitter ist keineswegs starr – es bewegt sich mit dem Pariser Wetter.

            An heißen Julitagen dehnt **Wärmeausdehnung** das Schmiedeeisen so stark aus, dass der Turm bis zu **15 Zentimeter höher** wird und sich leicht von der Sonne wegbiegt.

            Quelle: SETE — Archiv der Tour Eiffel
            """,
            deepDiveWithSource: """
            Schmiedeeisen dehnt sich um rund 12 Mikrometer pro Meter und Grad Celsius aus. Zwischen frostigen Winterstürmen und 40 °C im Hochsommer wächst der 300-Meter-Bau messbar in die Höhe.

            Da die Sonne jeweils nur eine Seite erwärmt, neigt sich die Turmspitze im Tagesverlauf zusätzlich um bis zu 18 Zentimeter von der Sonne fort.

            Quelle: Gustave Eiffel, La Tour de Trois Cents Mètres (1900)
            """
        ),
        GuestStaticPost(
            id: "napoleon-rabbits",
            categoryId: "history",
            title: "Als Napoleon von einer Herde Kaninchen verjagt wurde",
            tags: ["Geschichte", "Kurioses", "Frankreich"],
            bodyWithSource: """
            Zur Feier des Friedens von Tilsit **1807** organisierte Napoleons Stabschef eine Hasenjagd – kaufte dafür jedoch versehentlich Hunderte *zahme Stallkaninchen*.

            Kaum öffneten sich die Käfige, stürmten die Tiere in Richtung Napoleon als vermeintlichen Futterbringer und kletterten an seinem Mantel hoch, bis der Kaiser in die Kutsche floh.

            Quelle: David Chandler, The Campaigns of Napoleon (1966)
            """,
            deepDiveWithSource: """
            Marschall Alexandre Berthier wollte den siegreichen Generälen etwas Großes bieten und ließ aus Bauernhöfen bis zu tausend zahme Kaninchen zusammentragen.

            Völlig unbeeindruckt von Jagdhörnern bildeten die hungrigen Tiere zwei Flanken und stürmten Napoleons Stiefel unter schallendem Gelächter der Offiziere.

            Quelle: Memoirs of Baron Thiébault (1896)
            """
        ),
        GuestStaticPost(
            id: "hitchcock-psycho-syrup",
            categoryId: "film",
            title: "Warum in Psycho Schokoladensirup statt Kunstblut floss",
            tags: ["Kino", "Regie", "Handwerk"],
            bodyWithSource: """
            Alfred Hitchcock drehte *Psycho* (1960) mit einem TV-Team in Schwarz-Weiß – auch um Zensurkürzungen bei farbiger Gewalt zu umgehen.

            Rotes Theaterblut wirkte auf Monochromfilm zu blass; daher griff die Requisite zu **Bosco-Schokoladensirup**, dessen *dicke Textur* im Abfluss exakt wie echtes Blut wirkte.

            Quelle: Stephen Rebello, Alfred Hitchcock and the Making of Psycho (1990)
            """,
            deepDiveWithSource: """
            Für 45 Sekunden Duschszene drehte Hitchcock sieben Tage lang 78 Kameraeinstellungen mit 52 Schnitten – ohne dass jemals eine Klinge sichtbar Haut berührte.

            Auf panchromatischem Schwarz-Weiß-Film sorgte erst der dunkle Karamellton des Sirups gegen weiße Fliesen für den schockierenden Kontrast.

            Quelle: Janet Leigh & Christopher Nickens, Psycho: Behind the Scenes (1995)
            """
        ),
        GuestStaticPost(
            id: "venus-day-year",
            categoryId: "science",
            title: "Auf der Venus dauert ein Tag länger als ein ganzes Jahr",
            tags: ["Wissenschaft", "Astronomie", "Weltraum"],
            bodyWithSource: """
            Die Venus umrundet die Sonne in **224,7 Erdtagen**, dreht sich aber rückwärts so träge um die eigene Achse, dass eine volle Rotation **243 Erdtage** benötigt.

            Auf ihr geht die Sonne deshalb nicht im Osten, sondern im **Westen** auf und kriecht in Zeitlupe über den schwefelgelben Himmel.

            Quelle: NASA Jet Propulsion Laboratory — Planetary Fact Sheet
            """,
            deepDiveWithSource: """
            Forschende unterscheiden den *siderischen Tag* (243 Erdtage relativ zu Sternen) vom *Sonnentag* (rund 116,75 Erdtage von Mittag zu Mittag wegen des Rückwärtsdralls).

            Dichte Gezeiten in der Venusatmosphäre lassen diese Rotationsdauer über Jahrzehnte sogar minimal schwanken.

            Quelle: Jean-Luc Margot et al., Nature Astronomy (2021)
            """
        ),
        GuestStaticPost(
            id: "volcano-bicycle",
            categoryId: "history",
            title: "Wie ein Vulkanausbruch die Erfindung des Fahrrads auslöste",
            tags: ["Geschichte", "Design", "Klima"],
            bodyWithSource: """
            Der Ausbruch des **Tambora** 1815 verdunkelte die Atmosphäre und brachte 1816 das *Jahr ohne Sommer*. Ernten fielen aus, und Hafer wurde für Pferde unbezahlbar.

            Auf der Suche nach pferdefreiem Transport erfand Karl Drais 1817 in Mannheim die zweirädrige **Laufmaschine** – die Urform unseres Fahrrads.

            Quelle: Gillen D'Arcy Wood, Tambora (2014)
            """,
            deepDiveWithSource: """
            Auf seiner ersten Vorführfahrt schaffte Drais 13 Kilometer in unter einer Stunde und ließ Postkutschen hinter sich. Füße drückten sich vom Boden ab, der Lenker hielt das Gleichgewicht.

            Pedale kamen erst vier Jahrzehnte später hinzu, doch das Prinzip zweier Räder in einer Spur entstand aus purer Klimakrise.

            Quelle: Hans-Erhard Lessing, Automobilität: Karl Drais (2003)
            """
        ),
        GuestStaticPost(
            id: "babylon-copper-complaint",
            categoryId: "history",
            title: "Die älteste bekannte Kundenbeschwerde ist 3.750 Jahre alt",
            tags: ["Geschichte", "Mesopotamien", "Kultur"],
            bodyWithSource: """
            Um **1750 v. Chr.** ritzte ein verärgerter Käufer namens Nanni eine Wut-Tafel an den Kupferhändler **Ea-nasir** in Ur: Das gelieferte Metall tauge nichts und sein Bote sei gedemütigt worden.

            Archäologen fanden diese Tontafel *mitten in Ea-nasirs eigenem Haus* – fein säuberlich abgelegt neben vielen weiteren Reklamationen.

            Quelle: British Museum Collection, U.16800 (Ur Excavations)
            """,
            deepDiveWithSource: """
            Auf akkadischer Keilschrift fragt Nanni wütend, wofür Ea-nasir ihn eigentlich halte, und fordert sein Geld zurück.

            Sir Leonard Woolleys Grabung deckte ein ganzes Beschwerde-Archiv des bronzezeitlichen Händlers auf – und machte Ea-nasir posthum zur Ikone schlechter Bewertungen.

            Quelle: A. Leo Oppenheim, Letters from Mesopotamia (1967)
            """
        ),
        GuestStaticPost(
            id: "nintendo-1889",
            categoryId: "history",
            title: "Nintendo wurde im selben Jahr wie der Eiffelturm gegründet",
            tags: ["Geschichte", "Gaming", "Japan"],
            bodyWithSource: """
            Lange vor Super Mario eröffnete Fusajiro Yamauchi im **September 1889** in Kyoto das Unternehmen **Nintendo Koppai** – nur Monate nach der Eröffnung des Pariser Eiffelturms.

            Über siebzig Jahre lang überlebte der Betrieb vor allem durch handbemalte *Hanafuda*-Blumenkarten aus Maulbeerbaumrinde.

            Quelle: Florent Gorges, The History of Nintendo 1889–1980 (2012)
            """,
            deepDiveWithSource: """
            Da Spielkarten mit Zahlen im Meiji-Japan wegen Glücksspielgesetzen reguliert waren, fanden illustrierte Hanafuda-Blätter mit Jahreszeitenmotiven begeisterte Kundschaft.

            Unter Enkel Hiroshi Yamauchi testete Nintendo ab 1949 Disney-Karten, Taxis und Elektronikspielzeug, bevor Game & Watch den Weg zu Weltkonsolen ebnete.

            Quelle: David Sheff, Game Over (1993)
            """
        ),
        GuestStaticPost(
            id: "sharks-older-than-trees",
            categoryId: "science",
            title: "Haie sind älter als Bäume – und älter als Saturns Ringe",
            tags: ["Wissenschaft", "Natur", "Zeitlinie"],
            bodyWithSource: """
            Fossile Haischuppen reichen rund **450 Millionen Jahre** ins Ordovizium zurück – etwa *90 Millionen Jahre bevor* erste echte Bäume an Land wuchsen.

            Cassini-Daten zeigen zudem, dass Saturns Eisringe wohl nur **10 bis 100 Millionen Jahre** alt sind; Haie schwammen also schon durch Urmeere, lange bevor Saturn seinen Ring bekam.

            Quelle: Luciano Iess et al., Science (2019) & Ivanov et al., Paleobiology
            """,
            deepDiveWithSource: """
            Haie überlebten sämtliche fünf großen Massenaussterben der Erdgeschichte, darunter das Perm-Trias-Ereignis vor 252 Millionen Jahren.

            Schwerkraft- und Staubmessungen der Cassini-Sonde zeigten hingegen, dass Saturns Ringe erstaunlich sauber und leicht sind – ein klares Indiz für ein geologisch junges Alter.

            Quelle: Sascha Kempf et al., Science Advances (2023)
            """
        ),
        GuestStaticPost(
            id: "mario-mustache-pixels",
            categoryId: "design",
            title: "Warum Mario Mütze, Latzhose und Schnurrbart trägt",
            tags: ["Design", "Gaming", "Handwerk"],
            bodyWithSource: """
            Als Shigeru Miyamoto **1981** *Donkey Kong* entwarf, erlaubte die Arcade-Hardware nur ein **16×16-Pixel-Raster** mit drei Farben pro Figur.

            Deshalb bekam Mario eine **Mütze** statt animierter Haare, eine **rote Latzhose** zur Trennung von Armen und Torso sowie einen **Schnurrbart**, um Nase und Gesicht ohne Mund lesbar zu machen.

            Quelle: Shigeru Miyamoto, Iwata Asks: New Super Mario Bros. Wii (2009)
            """,
            deepDiveWithSource: """
            Röhrenmonitore verwischten feine Details bei 60 Bildern pro Sekunde sofort. Durch harte Kontraste wurden 256 winzige Pixel zur unverwechselbaren Silhouette in jeder Spielhalle.

            Was heute als klassisches Charakterdesign gilt, entstand direkt aus knappen Speicherbudgets der 8-Bit-Pionierzeit.

            Quelle: Chris Kohler, Power-Up (2004)
            """
        ),
        GuestStaticPost(
            id: "pigeons-monet-picasso",
            categoryId: "science",
            title: "Wie Tauben lernten, Monet von Picasso zu unterscheiden",
            tags: ["Wissenschaft", "Kunst", "Psychologie"],
            bodyWithSource: """
            **1995** trainierte der Psychologe Shigeru Watanabe an der Keio-Universität Tauben mit Futterbelohnung auf Gemälde von **Monet** und **Picasso**.

            Selbst bei völlig *unbekannten Bildern* – sogar auf dem Kopf stehend oder in Schwarz-Weiß – unterschieden die Vögel Impressionismus von Kubismus mit über **90 % Genauigkeit** und gewannen den Ig-Nobelpreis.

            Quelle: Shigeru Watanabe et al., JEAB (1995)
            """,
            deepDiveWithSource: """
            Um reines Auswendiglernen auszuschließen, zeigte das Team neue Werke verwandter Künstler: Auf Monet geschulte Tauben erkannten spontan Renoir und Cézanne, Picasso-Tauben ordneten Braque und Matisse zu.

            Vögel besitzen vier Farbrezeptortypen und erkennen komplexe Stilmerkmale erstaunlich zuverlässig.

            Quelle: Shigeru Watanabe, Animal Cognition (2001)
            """
        ),
        GuestStaticPost(
            id: "chess-more-than-atoms",
            categoryId: "science",
            title: "Im Schach gibt es mehr mögliche Partien als Atome im All",
            tags: ["Wissenschaft", "Mathematik", "Kultur"],
            bodyWithSource: """
            Informationstheorie-Pionier **Claude Shannon** berechnete 1950 eine konservative Untergrenze für legale Schachverläufe: **10¹²⁰ Partien** – heute bekannt als *Shannon-Zahl*.

            Das gesamte beobachtbare Universum enthält schätzungsweise **10⁸⁰ Atome**. Nach wenigen Eröffnungszügen sprengt das Brett bereits jede kosmische Dimension.

            Quelle: Claude E. Shannon, Philosophical Magazine (1950)
            """,
            deepDiveWithSource: """
            Nach je einem Zug existieren 400 Stellungen, nach je drei Zügen über 121 Millionen Verläufe. Shannon legte rund 30 legale Züge pro Halbzug über durchschnittlich 40 Züge zugrunde: (10³)^40 = 10¹²⁰.

            Selbst die Zahl legal erreichbarer Brettpositionen überschreitet laut neueren Analysen 10⁴⁴.

            Quelle: John Tromp & Stefan Edelkamp, Chess Game Complexity (2022)
            """
        )
    ]

    // MARK: - Spanish (12 Extra Stories)

    private static let extraSpanishPosts: [GuestStaticPost] = [
        GuestStaticPost(
            id: "cleopatra-iphone",
            categoryId: "history",
            title: "Cleopatra vivió más cerca del iPhone que de la Gran Pirámide",
            tags: ["Historia", "Cronología", "Egipto"],
            bodyWithSource: """
            La Gran Pirámide de Guiza se levantó hacia el **2560 a. C.** Cleopatra VII nació en el **69 a. C.**, casi *2.500 años después* de aquellas obras.

            Entre Cleopatra y el lanzamiento del iPhone en 2007 median solo **2.076 años**, situando a la última reina egipcia más cerca de nuestros teléfonos que de los constructores de Guiza.

            Fuente: Joyce Tyldesley, Cleopatra: Last Queen of Egypt (2008)
            """,
            deepDiveWithSource: """
            El Antiguo Egipto abarca más de tres milenios, aunque solemos imaginarlo como una sola postal. Cuando Julio César llegó a Alejandría, la Gran Pirámide ya era más antigua para Cleopatra de lo que César es para nosotros.

            Turistas romanos incluso dejaban grafitis en los templos de Guiza, admirando ruinas de un pasado que ya llevaba dos mil años desaparecido.

            Fuente: Toby Wilkinson, The Rise and Fall of Ancient Egypt (2010)
            """
        ),
        GuestStaticPost(
            id: "eiffel-summer-growth",
            categoryId: "science",
            title: "Por qué la Torre Eiffel crece 15 centímetros cada verano",
            tags: ["Ciencia", "Arquitectura", "París"],
            bodyWithSource: """
            La celosía de hierro forjado de 7.300 toneladas diseñada por Gustave Eiffel no es inmóvil: respira con el clima de París.

            En tardes calurosas de julio, la **dilatación térmica** estira sus vigas hasta hacer que el monumento sea **15 centímetros más alto** y se incline suavemente en dirección contraria al sol.

            Fuente: SETE — Archivos de la Tour Eiffel
            """,
            deepDiveWithSource: """
            El hierro forjado se expande unos 12 micrómetros por metro cada grado Celsius. Entre el frío invernal y los 40 °C estivales, la estructura de 300 metros gana varios centímetros medibles.

            Como el sol calienta una cara a la vez, la cima describe a diario un lento óvalo térmico que puede desplazarla hasta 18 centímetros.

            Fuente: Gustave Eiffel, La Tour de Trois Cents Mètres (1900)
            """
        ),
        GuestStaticPost(
            id: "napoleon-rabbits",
            categoryId: "history",
            title: "El día en que una horda de conejos ahuyentó a Napoleón",
            tags: ["Historia", "Curiosidades", "Francia"],
            bodyWithSource: """
            Tras firmar los Tratados de Tilsit en **1807**, Napoleón celebró con una cacería organizada por su jefe de estado mayor, quien compró por error cientos de *conejos domésticos* en lugar de liebres salvajes.

            Al abrir las jaulas, los conejos vieron al Emperador como quien trae comida y cargaron en masa trepando por su abrigo hasta obligarlo a huir en su carruaje.

            Fuente: David Chandler, The Campaigns of Napoleon (1966)
            """,
            deepDiveWithSource: """
            El mariscal Berthier reunió hasta mil conejos de granja para impresionar a los generales victoriosos.

            Sin asustarse por los cuernos de caza, la marea peluda rodeó las botas de Napoleón en dos flancos ante las carcajadas de los presentes, hasta que el cochero tuvo que fustigar los caballos para escapar.

            Fuente: Memoirs of Baron Thiébault (1896)
            """
        ),
        GuestStaticPost(
            id: "hitchcock-psycho-syrup",
            categoryId: "film",
            title: "Por qué la ducha de Psicosis usó sirope de chocolate",
            tags: ["Cine", "Dirección", "Oficio"],
            bodyWithSource: """
            Alfred Hitchcock rodó *Psicosis* (1960) con un equipo televisivo de bajo presupuesto y en blanco y negro, en parte para esquivar a los censores.

            La sangre roja de utilería salía apagada en monocromo, así que usaron **sirope de chocolate Bosco**, cuya *textura espesa* y tono oscuro resultaban perfectos remolinando por el desagüe.

            Fuente: Stephen Rebello, Alfred Hitchcock and the Making of Psycho (1990)
            """,
            deepDiveWithSource: """
            Hitchcock invirtió siete días en 78 planos y 52 cortes vertiginosos para apenas 45 segundos de escena, logrando que el cuchillo nunca se viera tocar la piel.

            Sobre película pancromática, el caramelo oscuro del sirope ofrecía el contraste exacto contra los azulejos blancos.

            Fuente: Janet Leigh & Christopher Nickens, Psycho: Behind the Scenes (1995)
            """
        ),
        GuestStaticPost(
            id: "venus-day-year",
            categoryId: "science",
            title: "En Venus un solo día dura más que un año entero",
            tags: ["Ciencia", "Astronomía", "Espacio"],
            bodyWithSource: """
            Venus tarda **224,7 días terrestres** en dar la vuelta al Sol, pero gira al revés sobre sí mismo con tanta lentitud que necesita **243 días terrestres** para completar una rotación.

            Si esperaras el amanecer bajo sus nubes sulfúricas, verías salir el Sol por el **oeste** a paso glaciar.

            Fuente: NASA Jet Propulsion Laboratory — Planetary Fact Sheet
            """,
            deepDiveWithSource: """
            Los astrónomos distinguen el *día sidéreo* (243 días terrestres frente a las estrellas) del *día solar* (116,75 días terrestres entre mediodías debido al giro retrógrado).

            Incluso las densas mareas térmicas de su atmósfera aceleran o frenan sutilmente esa rotación con el paso de las décadas.

            Fuente: Jean-Luc Margot et al., Nature Astronomy (2021)
            """
        ),
        GuestStaticPost(
            id: "volcano-bicycle",
            categoryId: "history",
            title: "El volcán que dio origen a la bicicleta",
            tags: ["Historia", "Diseño", "Clima"],
            bodyWithSource: """
            La erupción del **monte Tambora** en 1815 cubrió el planeta de cenizas y provocó 1816, el *Año sin verano*. Las cosechas fallaron en Europa y escaseó la avena para los caballos.

            Buscando transporte sin equinos en 1817, Karl Drais creó la **Laufmaschine** de madera y dos ruedas: la antepasada directa de la bicicleta.

            Fuente: Gillen D'Arcy Wood, Tambora (2014)
            """,
            deepDiveWithSource: """
            Drais recorrió 13 kilómetros en menos de una hora en Mannheim impulsándose con los pies y equilibrándose con el manillar, superando a las diligencias de correos.

            Los pedales llegarían cuarenta años después, pero la geometría de dos ruedas en línea nació de una crisis alimentaria global.

            Fuente: Hans-Erhard Lessing, Automobilität: Karl Drais (2003)
            """
        ),
        GuestStaticPost(
            id: "babylon-copper-complaint",
            categoryId: "history",
            title: "La queja de cliente más antigua tiene 3.750 años",
            tags: ["Historia", "Mesopotamia", "Cultura"],
            bodyWithSource: """
            Hacia el **1750 a. C.**, un comprador llamado Nanni grabó una furiosa tablilla de arcilla para el mercader **Ea-nasir** en Ur, denunciando lingotes de cobre mediocres y maltrato a su mensajero.

            Los arqueólogos hallaron la tablilla *dentro de la propia casa de Ea-nasir*, archivada junto a decenas de quejas similares.

            Fuente: Colección del British Museum, Objeto U.16800 (Ur)
            """,
            deepDiveWithSource: """
            Escrita en cuneiforme acadio, la carta pregunta: *"¿Por quién me tomas para tratar así a alguien como yo?"* y exige la devolución íntegra del dinero.

            Las excavaciones de Leonard Woolley revelaron todo un archivo de reclamos contra el comerciante, convirtiéndolo en leyenda eterna de las reseñas de una estrella.

            Fuente: A. Leo Oppenheim, Letters from Mesopotamia (1967)
            """
        ),
        GuestStaticPost(
            id: "nintendo-1889",
            categoryId: "history",
            title: "Nintendo se fundó el mismo año en que abrió la Torre Eiffel",
            tags: ["Historia", "Videojuegos", "Japón"],
            bodyWithSource: """
            Mucho antes de Mario o Switch, Fusajiro Yamauchi abrió **Nintendo Koppai** en Kioto en **septiembre de 1889**, apenas unas semanas después de inaugurarse la Torre Eiffel.

            Durante más de setenta años la compañía sobrevivió pintando a mano cartas tradicionales *hanafuda* sobre corteza de morera.

            Fuente: Florent Gorges, The History of Nintendo 1889–1980 (2012)
            """,
            deepDiveWithSource: """
            Como las barajas numeradas estaban restringidas en el Japón Meiji por leyes contra el juego, las cartas ilustradas con flores estacionales esquivaron la prohibición y arrasaron en Kioto.

            Su nieto Hiroshi Yamauchi diversificó el negocio desde 1949 probando cartas Disney, taxis y juguetes electrónicos hasta el salto digital con Game & Watch.

            Fuente: David Sheff, Game Over (1993)
            """
        ),
        GuestStaticPost(
            id: "sharks-older-than-trees",
            categoryId: "science",
            title: "Los tiburones son más antiguos que los árboles y los anillos de Saturno",
            tags: ["Ciencia", "Naturaleza", "Cronología"],
            bodyWithSource: """
            Las escamas fósiles de tiburón datan de hace **450 millones de años** en el Ordovícico, unos *90 millones de años antes* de que aparecieran los primeros árboles en tierra firme.

            Según la sonda Cassini, los anillos helados de Saturno tendrían entre **10 y 100 millones de años**: los tiburones son al menos *cuatro veces* más antiguos.

            Fuente: Luciano Iess et al., Science (2019) & Ivanov et al., Paleobiology
            """,
            deepDiveWithSource: """
            Los tiburones sobrevivieron a las cinco grandes extinciones masivas de la Tierra, incluida la del Pérmico-Triásico que borró más del 80 % de la vida marina.

            Las mediciones finales de Cassini mostraron anillos sorprendentemente limpios de polvo cósmico, señal de un origen astronómico reciente.

            Fuente: Sascha Kempf et al., Science Advances (2023)
            """
        ),
        GuestStaticPost(
            id: "mario-mustache-pixels",
            categoryId: "design",
            title: "Por qué Mario lleva gorra, peto y bigote",
            tags: ["Diseño", "Videojuegos", "Oficio"],
            bodyWithSource: """
            Al diseñar *Donkey Kong* en **1981**, Shigeru Miyamoto disponía de una cuadrícula de apenas **16×16 píxeles** y tres colores por personaje.

            Le puso **gorra** porque animar el pelo era imposible, **peto rojo** para distinguir los brazos del torso y **bigote** para marcar su nariz sin necesidad de dibujar boca.

            Fuente: Shigeru Miyamoto, Iwata Asks: New Super Mario Bros. Wii (2009)
            """,
            deepDiveWithSource: """
            Las pantallas CRT difuminaban los detalles finos a 60 cuadros por segundo. Convertir limitaciones técnicas en una silueta clara permitió reconocer al personaje de un vistazo en cualquier salón recreativo.

            Cada rasgo icónico de Mario nació de aquellos 256 pequeños cuadrados luminosos.

            Fuente: Chris Kohler, Power-Up (2004)
            """
        ),
        GuestStaticPost(
            id: "pigeons-monet-picasso",
            categoryId: "science",
            title: "Científicos enseñaron a palomas a distinguir a Monet de Picasso",
            tags: ["Ciencia", "Arte", "Psicología"],
            bodyWithSource: """
            En **1995**, el psicólogo Shigeru Watanabe de la Universidad de Keio entrenó palomas con recompensas de semillas para picotear cuadros de **Monet** frente a obras de **Picasso**.

            Incluso ante cuadros *nunca antes vistos* —o invertidos y en escala de grises—, distinguieron el Impresionismo del Cubismo con más del **90 % de acierto**, ganando un premio Ig Nobel.

            Fuente: Shigeru Watanabe et al., JEAB (1995)
            """,
            deepDiveWithSource: """
            Al probar generalización, las aves entrenadas con Monet reconocieron de inmediato a Renoir y Cézanne; las entrenadas con Picasso agruparon a Braque y Matisse.

            Con visión tetracromática y gran agudeza visual, las palomas demostraron que categorizar estilos artísticos no es exclusivo de humanos.

            Fuente: Shigeru Watanabe, Animal Cognition (2001)
            """
        ),
        GuestStaticPost(
            id: "chess-more-than-atoms",
            categoryId: "science",
            title: "Hay más partidas posibles de ajedrez que átomos en el universo",
            tags: ["Ciencia", "Matemáticas", "Cultura"],
            bodyWithSource: """
            En 1950, el pionero de la teoría de la información **Claude Shannon** calculó un límite inferior conservador para el ajedrez: **10¹²⁰ partidas posibles** (*Número de Shannon*).

            Se estima que todo el universo observable contiene alrededor de **10⁸⁰ átomos**; tras apenas unos pocos movimientos, el tablero supera cualquier cifra cósmica.

            Fuente: Claude E. Shannon, Philosophical Magazine (1950)
            """,
            deepDiveWithSource: """
            Con una jugada por bando existen 400 posiciones; tras tres jugadas cada uno superan los 121 millones de caminos. Shannon promedió 40 turnos con unas 30 opciones legales por turno: (10³)^40 = 10¹²⁰.

            Cálculos modernos estiman además que solo las posiciones legales únicas en 8×8 rebasan 10⁴⁴.

            Fuente: John Tromp & Stefan Edelkamp, Chess Game Complexity (2022)
            """
        )
    ]

    // MARK: - French (12 Extra Stories)

    private static let extraFrenchPosts: [GuestStaticPost] = [
        GuestStaticPost(
            id: "cleopatra-iphone",
            categoryId: "history",
            title: "Cléopâtre a vécu plus près de l'iPhone que de la Grande Pyramide",
            tags: ["Histoire", "Chronologie", "Égypte"],
            bodyWithSource: """
            La Grande Pyramide de Gizeh fut achevée vers **2560 av. J.-C.** Cléopâtre VII naquit en **69 av. J.-C.**, près de *2 500 ans plus tard*.

            Entre Cléopâtre et le premier iPhone en 2007, il n'y a que **2 076 ans** : elle était plus proche de nos smartphones que des bâtisseurs de Gizeh.

            Source : Joyce Tyldesley, Cleopatra: Last Queen of Egypt (2008)
            """,
            deepDiveWithSource: """
            L'Égypte antique s'étend sur plus de trois millénaires. Quand Jules César débarqua à Alexandrie, la Grande Pyramide était déjà plus ancienne pour Cléopâtre que César ne l'est pour nous aujourd'hui.

            Des voyageurs romains gravaient déjà leurs noms sur les monuments de Gizeh, fascinés par un passé déjà vieux de deux mille ans.

            Source : Toby Wilkinson, The Rise and Fall of Ancient Egypt (2010)
            """
        ),
        GuestStaticPost(
            id: "eiffel-summer-growth",
            categoryId: "science",
            title: "Pourquoi la tour Eiffel grandit de 15 centimètres chaque été",
            tags: ["Science", "Architecture", "Paris"],
            bodyWithSource: """
            La dentelle de fer puddlé de 7 300 tonnes imaginée par Gustave Eiffel n'est pas figée : elle respire avec les saisons parisiennes.

            Lors des après-midi caniculaires de juillet, la **dilatation thermique** allonge la charpente jusqu'à **15 centimètres de plus** et l'incline légèrement à l'opposé du soleil.

            Source : SETE — Archives de la Tour Eiffel
            """,
            deepDiveWithSource: """
            Le fer puddlé s'allonge d'environ 12 micromètres par mètre et par degré Celsius. Entre les gels d'hiver et 40 °C en plein soleil, les 300 mètres d'acier gagnent plusieurs centimètres mesurables.

            Comme le soleil chauffe une façade à la fois, le sommet décrit chaque jour un léger ovale allant jusqu'à 18 centimètres.

            Source : Gustave Eiffel, La Tour de Trois Cents Mètres (1900)
            """
        ),
        GuestStaticPost(
            id: "napoleon-rabbits",
            categoryId: "history",
            title: "Le jour où Napoléon fut mis en déroute par des lapins",
            tags: ["Histoire", "Insolite", "France"],
            bodyWithSource: """
            Après les traités de Tilsit en **1807**, le chef d'état-major de Napoléon organisa une chasse – mais acheta par erreur des centaines de *lapins d'élevage apprivoisés* au lieu de lièvres sauvages.

            À l'ouverture des cages, affamés, ils reconnurent l'Empereur comme distributeur de repas et foncèrent sur lui en grimpant à sa redingote jusqu'à sa retraite en calèche.

            Source : David Chandler, The Campaigns of Napoleon (1966)
            """,
            deepDiveWithSource: """
            Le maréchal Berthier avait rassemblé jusqu'à mille lapins de ferme pour divertir les généraux victorieux.

            Insensibles aux cors de chasse, les bêtes débordèrent la garde sur deux flancs sous les éclats de rire des officiers, forçant les cochers à fouetter les chevaux pour dégager l'Empereur.

            Source : Memoirs of Baron Thiébault (1896)
            """
        ),
        GuestStaticPost(
            id: "hitchcock-psycho-syrup",
            categoryId: "film",
            title: "Pourquoi la scène de la douche dans Psychose utilisait du sirop de chocolat",
            tags: ["Cinéma", "Réalisation", "Métier"],
            bodyWithSource: """
            Alfred Hitchcock tourna *Psychose* (1960) avec une équipe TV à petit budget en noir et blanc – notamment pour éviter les ciseaux de la censure.

            Le faux sang rouge paraissait fade sur pellicule monochrome ; les accessoiristes choisirent du **sirop au chocolat Bosco**, dont la *viscosité épaisse* tourbillonnait avec réalisme dans le siphon.

            Source : Stephen Rebello, Alfred Hitchcock and the Making of Psycho (1990)
            """,
            deepDiveWithSource: """
            Hitchcock consacra sept jours à 78 placements de caméra et 52 coupes rapides pour 45 secondes d'écran, sans jamais montrer la lame toucher la peau.

            Sur film panchromatique, le brun brillant du sirop offrait le contraste exact sur la faïence blanche.

            Source : Janet Leigh & Christopher Nickens, Psycho: Behind the Scenes (1995)
            """
        ),
        GuestStaticPost(
            id: "venus-day-year",
            categoryId: "science",
            title: "Sur Vénus, un seul jour dure plus longtemps qu'une année entière",
            tags: ["Science", "Astronomie", "Espace"],
            bodyWithSource: """
            Vénus accomplit son orbite autour du Soleil en **224,7 jours terrestres**, mais tourne sur elle-même en sens inverse si lentement qu'il lui faut **243 jours terrestres** pour un tour complet.

            Sous ses nuages sulfuriques, le Soleil se lève à l'**ouest** et traverse le ciel au ralenti.

            Source : NASA Jet Propulsion Laboratory — Planetary Fact Sheet
            """,
            deepDiveWithSource: """
            Les astronomes distinguent le *jour sidéral* (243 jours terrestres face aux étoiles) du *jour solaire* (116,75 jours terrestres d'un midi à l'autre à cause de sa rotation rétrograde).

            Les puissantes marées thermiques de son atmosphère font même varier légèrement cette rotation au fil des décennies.

            Source : Jean-Luc Margot et al., Nature Astronomy (2021)
            """
        ),
        GuestStaticPost(
            id: "volcano-bicycle",
            categoryId: "history",
            title: "Comment une éruption volcanique a mené à l'invention du vélo",
            tags: ["Histoire", "Design", "Climat"],
            bodyWithSource: """
            L'éruption du **mont Tambora** en 1815 voila le ciel terrestre et causa 1816, l'*Année sans été*. Les récoltes gelèrent en Europe et l'avoine manqua pour nourrir les chevaux.

            Cherchant à rouler sans monture en 1817, Karl Drais conçut la **draisienne** en bois à deux roues : l'ancêtre direct de la bicyclette.

            Source : Gillen D'Arcy Wood, Tambora (2014)
            """,
            deepDiveWithSource: """
            Lors de son essai à Mannheim, Drais parcourut 13 kilomètres en moins d'une heure en poussant du pied, devançant les diligences postales.

            Les pédales n'apparurent que quarante ans plus tard, mais l'équilibre sur deux roues en ligne est né d'une crise climatique historique.

            Source : Hans-Erhard Lessing, Automobilität: Karl Drais (2003)
            """
        ),
        GuestStaticPost(
            id: "babylon-copper-complaint",
            categoryId: "history",
            title: "La plus ancienne plainte client connue a 3 750 ans",
            tags: ["Histoire", "Mésopotamie", "Culture"],
            bodyWithSource: """
            Vers **1750 av. J.-C.**, un client mécontent nommé Nanni grava une tablette d'argile furieuse au marchand de cuivre **Ea-nasir** à Ur, dénonçant des lingots médiocres et le mépris subi par son messager.

            Les archéologues retrouvèrent la tablette *dans la maison même d'Ea-nasir*, archivée parmi quantité d'autres plaintes similaires.

            Source : British Museum Collection, U.16800 (Ur)
            """,
            deepDiveWithSource: """
            En akkadien cunéiforme, Nanni s'indigne : *« Pour qui me prends-tu pour traiter ainsi quelqu'un comme moi ? »* et réclame remboursement intégral.

            Les fouilles de Leonard Woolley ont exhumé tout un dossier de réclamations chez ce négociant de l'âge du Bronze.

            Source : A. Leo Oppenheim, Letters from Mesopotamia (1967)
            """
        ),
        GuestStaticPost(
            id: "nintendo-1889",
            categoryId: "history",
            title: "Nintendo a été fondée la même année que la tour Eiffel",
            tags: ["Histoire", "Jeux vidéo", "Japon"],
            bodyWithSource: """
            Bien avant Mario ou la Switch, Fusajiro Yamauchi fonda **Nintendo Koppai** à Kyoto en **septembre 1889**, quelques semaines seulement après l'inauguration de la tour Eiffel.

            Pendant plus de soixante-dix ans, la maison vécut de cartes traditionnelles *hanafuda* peintes à la main sur écorce de mûrier.

            Source : Florent Gorges, L'Histoire de Nintendo 1889–1980 (2012)
            """,
            deepDiveWithSource: """
            Les cartes numérotées étant strictement encadrées au Japon sous l'ère Meiji contre les jeux d'argent, les jeux illustrés de fleurs saisonnières contournèrent l'interdit et conquirent Kyoto.

            À partir de 1949, Hiroshi Yamauchi multiplia les paris jusqu'au succès électronique mondial amorcé avec Game & Watch.

            Source : David Sheff, Game Over (1993)
            """
        ),
        GuestStaticPost(
            id: "sharks-older-than-trees",
            categoryId: "science",
            title: "Les requins sont plus vieux que les arbres et les anneaux de Saturne",
            tags: ["Science", "Nature", "Chronologie"],
            bodyWithSource: """
            Des écailles fossiles de requins remontent à environ **450 millions d'années** à l'Ordovicien, quelque *90 millions d'années avant* les premiers grands arbres terrestres.

            Les données de Cassini montrent que les anneaux glacés de Saturne n'auraient que **10 à 100 millions d'années** : les requins sont au moins *quatre fois* plus anciens.

            Source : Luciano Iess et al., Science (2019) & Ivanov et al., Paleobiology
            """,
            deepDiveWithSource: """
            Les requins ont traversé les cinq grandes extinctions de masse de la Terre, y compris la crise Permien-Trias qui effaça plus de 80 % des espèces marines.

            Les ultimes mesures de gravité de Cassini ont révélé des anneaux trop propres et légers pour être contemporains de la formation du Système solaire.

            Source : Sascha Kempf et al., Science Advances (2023)
            """
        ),
        GuestStaticPost(
            id: "mario-mustache-pixels",
            categoryId: "design",
            title: "Pourquoi Mario porte une casquette, une salopette et une moustache",
            tags: ["Design", "Jeux vidéo", "Savoir-faire"],
            bodyWithSource: """
            En créant *Donkey Kong* en **1981**, Shigeru Miyamoto ne disposait que d'une grille de **16×16 pixels** et trois couleurs par sprite.

            Il ajouta une **casquette** faute de pouvoir animer les cheveux, une **salopette rouge** pour détacher les bras du buste et une **moustache** pour souligner le nez sans dessiner de bouche.

            Source : Shigeru Miyamoto, Iwata Asks: New Super Mario Bros. Wii (2009)
            """,
            deepDiveWithSource: """
            Les écrans cathodiques floutaient le moindre détail à 60 images par seconde. Transformer ces limites matérielles en silhouette forte rendait le personnage lisible au premier coup d'œil.

            Toute une icône mondiale est née de 256 minuscules carrés lumineux.

            Source : Chris Kohler, Power-Up (2004)
            """
        ),
        GuestStaticPost(
            id: "pigeons-monet-picasso",
            categoryId: "science",
            title: "Des chercheurs ont appris à des pigeons à distinguer Monet de Picasso",
            tags: ["Science", "Art", "Psychologie"],
            bodyWithSource: """
            En **1995**, le psychologue Shigeru Watanabe à l'université Keio entraîna des pigeons avec des graines à différencier les toiles de **Monet** de celles de **Picasso**.

            Même devant des œuvres *jamais vues* – ou retournées et en noir et blanc –, les oiseaux séparèrent impressionnisme et cubisme avec plus de **90 % de réussite**, décrochant un prix Ig Nobel.

            Source : Shigeru Watanabe et al., JEAB (1995)
            """,
            deepDiveWithSource: """
            Pour écarter toute mémorisation simple, l'équipe testa de nouveaux peintres : les pigeons entraînés sur Monet reconnurent Renoir et Cézanne ; ceux sur Picasso classèrent Braque et Matisse.

            Dotés d'une vision tétrachromatique, les pigeons maîtrisent une véritable généralisation stylistique.

            Source : Shigeru Watanabe, Animal Cognition (2001)
            """
        ),
        GuestStaticPost(
            id: "chess-more-than-atoms",
            categoryId: "science",
            title: "Il existe plus de parties d'échecs possibles que d'atomes dans l'univers",
            tags: ["Science", "Maths", "Culture"],
            bodyWithSource: """
            En 1950, **Claude Shannon**, père de la théorie de l'information, estima une borne inférieure prudente du nombre de parties légales : **10¹²⁰ parties** (*nombre de Shannon*).

            L'univers observable compterait environ **10⁸⁰ atomes** : après quelques coups d'ouverture seulement, l'échiquier dépasse chaque particule visible.

            Source : Claude E. Shannon, Philosophical Magazine (1950)
            """,
            deepDiveWithSource: """
            Après un coup chacun, 400 positions existent ; après trois coups chacun, plus de 121 millions de trajectoires s'ouvrent. Shannon retint une moyenne de 40 coups avec environ 30 réponses légales par demi-coup : (10³)^40 = 10¹²⁰.

            Les calculs actuels montrent aussi que le seul nombre de positions accessibles dépasse 10⁴⁴.

            Source : John Tromp & Stefan Edelkamp, Chess Game Complexity (2022)
            """
        )
    ]

    // MARK: - Japanese (12 Extra Stories)

    private static let extraJapanesePosts: [GuestStaticPost] = [
        GuestStaticPost(
            id: "cleopatra-iphone",
            categoryId: "history",
            title: "クレオパトラはピラミッドよりiPhoneに近い時代を生きた",
            tags: ["歴史", "年表", "エジプト"],
            bodyWithSource: """
            ギザの大ピラミッドが完成したのは紀元前**2560年**ごろ。クレオパトラ7世の誕生は紀元前**69年**で、建設から実に*約2,500年後*です。

            彼女と2007年の初代iPhone発売との隔たりはわずか**2,076年**。古代エジプト最後の女王は、ピラミッドよりもスマートフォンに近い時代に生きていました。

            出典: Joyce Tyldesley, Cleopatra: Last Queen of Egypt (2008)
            """,
            deepDiveWithSource: """
            古代エジプト史は3,000年以上にわたるため、後世のイメージでは一続きの風景に見えがちです。しかしカエサルがアレクサンドリアへ上陸した時点で、大ピラミッドはすでに現在の私たちから見るカエサル以上に昔の存在でした。

            当時のローマ人旅行者も、二千年前に消えた王朝の遺跡へ観光の落書きを刻んでいたほどです。

            出典: Toby Wilkinson, The Rise and Fall of Ancient Egypt (2010)
            """
        ),
        GuestStaticPost(
            id: "eiffel-summer-growth",
            categoryId: "science",
            title: "エッフェル塔が毎年夏に15センチ伸びる理由",
            tags: ["科学", "建築", "パリ"],
            bodyWithSource: """
            ギュスターヴ・エッフェルが組んだ7,300トンの錬鉄製タワーは、パリの気候に合わせてわずかに呼吸するように伸び縮みします。

            真夏の炎天下では**熱膨張**により鉄骨が伸び、高さは最大**15センチ高く**なり、太陽と反対側へわずかに傾きます。

            出典: SETE — エッフェル塔運営公社アーカイブ
            """,
            deepDiveWithSource: """
            錬鉄は1℃上がるごとに1メートルあたり約12マイクロメートル膨張します。凍える冬と40℃近い夏の日差しを比べると、高さ300メートルの塔体全体ではっきり測れるほど伸びます。

            日光が当たる片面だけが強く温まるため、頂点は1日かけて最大18センチほどの楕円を描くようにゆっくり傾きます。

            出典: Gustave Eiffel, La Tour de Trois Cents Mètres (1900)
            """
        ),
        GuestStaticPost(
            id: "napoleon-rabbits",
            categoryId: "history",
            title: "ナポレオンがウサギの群れに敗走した日",
            tags: ["歴史", "珍事", "フランス"],
            bodyWithSource: """
            **1807年**、ティルジット条約を祝う狩猟会でナポレオンの参謀長は野ウサギの代わりに誤って数百匹の*飼い慣らされた食用ウサギ*を集めてしまいました。

            檻が開くとウサギたちは「餌をくれる人」と見てナポレオンへ一直線に突進し、コートにまでよじ登ったため皇帝は馬車へ退却する羽目になりました。

            出典: David Chandler, The Campaigns of Napoleon (1966)
            """,
            deepDiveWithSource: """
            ベルティエ元帥は将軍たちを喜ばせようと周辺の農家から最大千匹近いウサギを買い集めたと伝わります。

            猟銃や角笛にも動じず二手に分かれて突撃するウサギの波に、側近たちは大笑い。御者が馬に鞭を当ててようやく皇帝を救い出しました。

            出典: Memoirs of Baron Thiébault (1896)
            """
        ),
        GuestStaticPost(
            id: "hitchcock-psycho-syrup",
            categoryId: "film",
            title: "映画『サイコ』の血糊にチョコレートシロップが使われた理由",
            tags: ["映画", "演出", "制作秘話"],
            bodyWithSource: """
            ヒッチコックは1960年の『サイコ』をテレビ班による低予算のモノクロ作品として撮影しました。検閲で残酷描写を削られないための工夫でもありました。

            赤色の偽血は白黒フィルムだと薄く泥のように映るため、小道具班は**Boscoのチョコレートシロップ**を採用。排水口へ渦巻く*濃密なとろみ*と漆黒の艶が本物そっくりでした。

            出典: Stephen Rebello, Alfred Hitchcock and the Making of Psycho (1990)
            """,
            deepDiveWithSource: """
            わずか45秒のシャワー場面に7日間・78のカメラ配置と52回のカット割りを投入し、刃が肌に触れる瞬間を一度も見せずに恐怖を演出しました。

            白いタイルに映える濃いシロップの反射光こそが、モノクロ映画史に刻まれる鮮烈な質感を生みました。

            出典: Janet Leigh & Christopher Nickens, Psycho: Behind the Scenes (1995)
            """
        ),
        GuestStaticPost(
            id: "venus-day-year",
            categoryId: "science",
            title: "金星の1日は、金星の1年よりも長い",
            tags: ["科学", "天文学", "宇宙"],
            bodyWithSource: """
            金星は地球の**224.7日**で太陽を1周しますが、逆向きの自転があまりにも遅く、1回転するのに**243日**もかかります。

            厚い硫酸の雲の下では、太陽は東ではなく**西**から昇り、途方もなくゆっくりと空を横切ります。

            出典: NASA Jet Propulsion Laboratory — Planetary Fact Sheet
            """,
            deepDiveWithSource: """
            天文学では恒星基準の*恒星日*（243日）と、正午から正午までの*太陽日*（逆回転の影響で116.75日）を区別します。

            さらに厚い大気の熱潮汐が、数十年単位で金星の自転速度をごくわずかに揺らしていることも観測で判明しています。

            出典: Jean-Luc Margot et al., Nature Astronomy (2021)
            """
        ),
        GuestStaticPost(
            id: "volcano-bicycle",
            categoryId: "history",
            title: "火山の巨大噴火が自転車の発明を生んだ背景",
            tags: ["歴史", "デザイン", "気候"],
            bodyWithSource: """
            1815年のインドネシア・**タンボラ山**噴火で世界が冷え込み、1816年は*夏のない年*となりました。欧州では不作が続き、馬を養うエンバクまで不足しました。

            馬に頼らない移動手段を探したドイツ人カール・ドライスは1817年、足で地面を蹴って進む木製二輪車**ドライジーネ**を発表し、自転車の祖となりました。

            出典: Gillen D'Arcy Wood, Tambora (2014)
            """,
            deepDiveWithSource: """
            ドライスはマンハイムでの試走で13キロを1時間未満で走り抜け、郵便馬車を上回る速さを示しました。

            ペダルの登場はその約40年後ですが、前後2輪を一直線に並べて走る発想は、食糧危機という切実な現実から生まれました。

            出典: Hans-Erhard Lessing, Automobilität: Karl Drais (2003)
            """
        ),
        GuestStaticPost(
            id: "babylon-copper-complaint",
            categoryId: "history",
            title: "世界最古のクレーム文書は3,750年前の粘土板",
            tags: ["歴史", "メソポタミア", "文化"],
            bodyWithSource: """
            紀元前**1750年**ごろ、ウルに住むナンニという買い手が銅商人**エア・ナシル**へ怒りの粘土板を送りました。「粗悪な銅を掴ませ、使者まで見下した」という抗議です。

            考古学者たちがこの粘土板を発見したのは、なんと*エア・ナシル本人の自宅*。他の怒れる客からの苦情文書の山と一緒に保管されていました。

            出典: British Museum Collection, U.16800 (Ur Excavations)
            """,
            deepDiveWithSource: """
            アッカド語の楔形文字で書かれた手紙には「私を誰だと思ってこのような侮辱をするのか」と記され、代金の返還を迫っています。

            レオナード・ウーリーの発掘で苦情コレクションが見つかったことで、この青銅器時代の商人は現代ネットで「星1レビューの伝説」として親しまれる存在になりました。

            出典: A. Leo Oppenheim, Letters from Mesopotamia (1967)
            """
        ),
        GuestStaticPost(
            id: "nintendo-1889",
            categoryId: "history",
            title: "任天堂の創業はエッフェル塔が開業したのと同じ1889年",
            tags: ["歴史", "ゲーム", "日本"],
            bodyWithSource: """
            マリオやゲーム機よりもはるか以前、山内房治郎が京都で**任天堂骨牌**を開いたのは**1889年9月**。パリにエッフェル塔が誕生したのと同じ年です。

            創業から70年以上にわたり、同社はコウゾ紙を手塗りで仕立てる伝統の*花札*で商いを支え続けました。

            出典: Florent Gorges, The History of Nintendo 1889–1980 (2012)
            """,
            deepDiveWithSource: """
            明治期の賭博取り締まりで数字入りトランプが規制される中、四季の草花を描いた花札は京都で人気を博しました。

            1949年に孫の山内溥が社長を継ぐと、プラスチック製トランプからタクシー事業、横井軍平のゲーム＆ウオッチへと挑戦を広げ、世界企業へ飛躍しました。

            出典: David Sheff, Game Over (1993)
            """
        ),
        GuestStaticPost(
            id: "sharks-older-than-trees",
            categoryId: "science",
            title: "サメは地上の木々よりも土星の環よりも古い",
            tags: ["科学", "自然", "年表"],
            bodyWithSource: """
            サメの鱗の化石は約**4億5,000万年前**のオルドビス紀にさかのぼり、陸上に最初の樹木が根づくより約*9,000万年も早く*海を泳いでいました。

            探査機カッシーニの観測によれば、土星の氷の環の年齢はわずか**1,000万〜1億年**。サメは土星の環より少なくとも*4倍*も長寿な存在です。

            出典: Luciano Iess et al., Science (2019) & Ivanov et al., Paleobiology
            """,
            deepDiveWithSource: """
            サメは海棲生物の8割以上が失われたペルム紀末の大量絶滅を含め、地球史上の五大絶滅すべてを生き延びました。

            一方、カッシーニ最終周回のデータでは土星の環に宇宙塵の汚れが極端に少ないことが分かり、天文学的にきわめて若い構造だと示されました。

            出典: Sascha Kempf et al., Science Advances (2023)
            """
        ),
        GuestStaticPost(
            id: "mario-mustache-pixels",
            categoryId: "design",
            title: "マリオが帽子・オーバーオール・口ひげを持つ理由",
            tags: ["デザイン", "ゲーム", "ドット絵"],
            bodyWithSource: """
            **1981年**に『ドンキーコング』を制作した宮本茂に許されたのは、わずか**16×16ドット**・3色という制約でした。

            髪の揺れを描けないため**帽子**をかぶせ、腕の動きを胴体から浮かせるため**赤いオーバーオール**を着せ、口を描かずに鼻と顔を区別するため**口ひげ**をつけたのです。

            出典: 宮本茂, 社長が訊く『New スーパーマリオブラザーズ Wii』 (2009)
            """,
            deepDiveWithSource: """
            当時のブラウン管モニターでは細かい線が滲んで消えてしまうため、一目で輪郭が伝わる記号化が不可欠でした。

            わずか256マスの制限が生んだ明快なシルエットが、今なお世界中で親しまれるデザインとなっています。

            出典: Chris Kohler, Power-Up (2004)
            """
        ),
        GuestStaticPost(
            id: "pigeons-monet-picasso",
            categoryId: "science",
            title: "モネとピカソの絵画を見分けたハトの実験",
            tags: ["科学", "美術", "心理学"],
            bodyWithSource: """
            **1995年**、慶應義塾大学の渡辺茂はエサの報酬を用いて、ハトに**モネ**と**ピカソ**の絵画を見分ける訓練を行いました。

            するとハトは*初見の作品*や上下逆・白黒の複製画でも印象派とキュビスムを**90%以上の精度**で判別し、イグ・ノーベル賞を受賞しました。

            出典: Shigeru Watanabe et al., Journal of the Experimental Analysis of Behavior (1995)
            """,
            deepDiveWithSource: """
            単なる丸暗記でないことを確かめるため別の画家の絵を見せると、モネ派のハトはルノワールやセザンヌを、ピカソ派のハトはブラックやマティスを同じグループに分類しました。

            4色型色覚を持つ鳥類の視覚が、抽象的な画風の法則まで捉えられることを示した研究です。

            出典: Shigeru Watanabe, Animal Cognition (2001)
            """
        ),
        GuestStaticPost(
            id: "chess-more-than-atoms",
            categoryId: "science",
            title: "チェスの可能な棋譜は宇宙の原子数より多い",
            tags: ["科学", "数学", "文化"],
            bodyWithSource: """
            情報理論の父**クロード・シャノン**は1950年、チェスの合法的な展開数の控えめな下限を**10¹²⁰通り**（*シャノン数*）と算出しました。

            観測可能な宇宙全体の原子数は約**10⁸⁰個**と見積もられており、序盤数手を進めるだけで宇宙の粒子数をはるかに上回ります。

            出典: Claude E. Shannon, Philosophical Magazine (1950)
            """,
            deepDiveWithSource: """
            白黒1手ずつで400通り、3手ずつ指せばすでに1億2,100万通りの枝分かれが生じます。シャノンは1局平均40手・1手あたり約30の合法手から (10³)^40 = 10¹²⁰ を導きました。

            現代の精密な計算でも、8×8盤面上の到達可能な合法局面だけで10⁴⁴を超えることが分かっています。

            出典: John Tromp & Stefan Edelkamp, Chess Game Complexity (2022)
            """
        )
    ]

    // MARK: - Korean (12 Extra Stories)

    private static let extraKoreanPosts: [GuestStaticPost] = [
        GuestStaticPost(
            id: "cleopatra-iphone",
            categoryId: "history",
            title: "클레오파트라는 피라미드보다 아이폰에 더 가까운 시대를 살았다",
            tags: ["역사", "연대표", "이집트"],
            bodyWithSource: """
            기자의 대피라미드가 세워진 시기는 기원전 **2560년** 무렵입니다. 클레오파트라 7세는 기원전 **69년**에 태어났으니 피라미드 완공보다 *약 2,500년 뒤*의 인물입니다.

            클레오파트라와 2007년 첫 아이폰 출시 사이의 간격은 단 **2,076년**. 고대 이집트 마지막 여왕은 피라미드 건축가보다 스마트폰 시대에 훨씬 더 가까웠습니다.

            출처: Joyce Tyldesley, Cleopatra: Last Queen of Egypt (2008)
            """,
            deepDiveWithSource: """
            고대 이집트 문명이 3천 년 넘게 이어졌기 때문에 우리는 종종 모든 시대를 한 장면으로 압축해 떠올립니다. 율리우스 카이사르가 알렉산드리아에 도착했을 때, 대피라미드는 이미 오늘날 우리가 느끼는 카이사르보다도 더 까마득한 과거였습니다.

            로마 여행자들 역시 기자 유적 벽면에 관광 낙서를 남기며 두 천 년 전 사라진 시대를 동경했습니다.

            출처: Toby Wilkinson, The Rise and Fall of Ancient Egypt (2010)
            """
        ),
        GuestStaticPost(
            id: "eiffel-summer-growth",
            categoryId: "science",
            title: "에펠탑은 왜 매년 여름 15센티미터 더 커질까?",
            tags: ["과학", "건축", "파리"],
            bodyWithSource: """
            귀스타브 에펠이 설계한 7,300톤짜리 연철 구조물은 파리의 계절에 따라 살아 숨 쉬듯 움직입니다.

            무더운 7월 오후가 되면 **열팽창**으로 철골이 늘어나 탑 전체 높이가 최대 **15센티미터** 높아지고, 햇빛 반대편으로 살짝 기울어집니다.

            출처: SETE — 에펠탑 운영공사 아카이브
            """,
            deepDiveWithSource: """
            연철은 기온이 1°C 오를 때마다 1미터당 약 12마이크로미터씩 늘어납니다. 혹한기의 겨울바람과 40°C에 달하는 한여름 햇볕을 비교하면 300미터 높이에서 분명한 차이가 나타납니다.

            태양이 한쪽 면만 집중적으로 달구기 때문에 꼭대기는 하루 동안 최대 18센티미터 규모의 완만한 타원을 그리며 기울어집니다.

            출처: Gustave Eiffel, La Tour de Trois Cents Mètres (1900)
            """
        ),
        GuestStaticPost(
            id: "napoleon-rabbits",
            categoryId: "history",
            title: "나폴레옹이 토끼 떼의 습격에 후퇴했던 날",
            tags: ["역사", "비화", "프랑스"],
            bodyWithSource: """
            **1807년** 틸지트 조약 체결을 기념해 나폴레옹의 참모장이 대규모 토끼 사냥을 준비했는데, 실수로 야생 산토끼 대신 *길들여진 사육 토끼* 수백 마리를 사 모았습니다.

            우리가 열리자 사냥감을 기대한 장군들 앞에 모인 토끼들은 오히려 먹이를 주는 주인이라며 나폴레옹의 코트까지 기어올랐고, 결국 황제는 마차로 피신했습니다.

            출처: David Chandler, The Campaigns of Napoleon (1966)
            """,
            deepDiveWithSource: """
            알렉상드르 베르티에 원수는 승전 장교들에게 성대한 사냥을 선사하려고 인근 농장에서 최대 천 마리에 가까운 토끼를 구해 왔습니다.

            사냥 나팔 소리에도 꿈쩍 않고 두 날개 진형으로 돌진하는 굶주린 토끼 떼에 장군들은 폭소를 터뜨렸고, 마부가 말을 몰아서야 위기를 벗어났습니다.

            출처: Memoirs of Baron Thiébault (1896)
            """
        ),
        GuestStaticPost(
            id: "hitchcock-psycho-syrup",
            categoryId: "film",
            title: "영화 〈싸이코〉의 샤워 신에 초콜릿 시럽을 쓴 이유",
            tags: ["영화", "연출", "제작비화"],
            bodyWithSource: """
            알프레드 히치콕은 1960년작 〈싸이코〉를 TV 제작진과 함께 저예산 흑백 영화로 찍었습니다. 컬러 유혈 장면으로 인한 검열을 피하려는 뜻도 있었습니다.

            붉은 가짜 피는 흑백 필름에서 흐릿하게 나와 소품팀은 **Bosco 초콜릿 시럽**을 선택했고, *묵직한 점성*과 짙은 광택이 배수구로 소용돌이치며 완벽한 충격을 남겼습니다.

            출처: Stephen Rebello, Alfred Hitchcock and the Making of Psycho (1990)
            """,
            deepDiveWithSource: """
            히치콕은 단 45초 분량의 장면을 찍으려 7일간 78개 카메라 세팅과 52번의 컷 편집을 감행해 칼이 피부에 닿는 컷 없이도 극한의 공포를 만들었습니다.

            하얀 타일 위에서 빛나는 진한 초콜릿 시럽의 대비가 흑백 공포 영화의 전설을 완성했습니다.

            출처: Janet Leigh & Christopher Nickens, Psycho: Behind the Scenes (1995)
            """
        ),
        GuestStaticPost(
            id: "venus-day-year",
            categoryId: "science",
            title: "금성에서는 하루가 일 년보다 더 길다",
            tags: ["과학", "천문학", "우주"],
            bodyWithSource: """
            금성이 태양을 한 바퀴 도는 데는 지구 날짜로 **224.7일**이 걸리지만, 반대 방향으로 너무 느리게 자전해 스스로 한 바퀴 도는 데 **243일**이 걸립니다.

            두꺼운 황산 구름 아래에서라면 태양은 동쪽이 아닌 **서쪽**에서 떠올라 아주 느리게 하늘을 건넙니다.

            출처: NASA Jet Propulsion Laboratory — Planetary Fact Sheet
            """,
            deepDiveWithSource: """
            천문학자들은 별을 기준으로 한 *항성일*(243일)과 정오에서 다음 정오까지의 *태양일*(역자전 덕분에 약 116.75일)을 구분합니다.

            또한 짙은 대기의 열 조석 현상이 수십 년 단위로 금성의 자전 속도를 미세하게 앞당기거나 늦춘다는 사실이 레이더 관측으로 밝혀졌습니다.

            출처: Jean-Luc Margot et al., Nature Astronomy (2021)
            """
        ),
        GuestStaticPost(
            id: "volcano-bicycle",
            categoryId: "history",
            title: "화산 대폭발이 자전거 발명을 이끈 사연",
            tags: ["역사", "디자인", "기후"],
            bodyWithSource: """
            1815년 인도네시아 **탐보라 화산** 폭발로 전 지구에 화산재가 덮이며 1816년 *여름 없는 해*가 닥쳤습니다. 흉작이 이어져 말을 먹일 귀리마저 사라졌습니다.

            말 없이 달릴 탈것을 고민한 독일의 카를 드라이스는 1817년 발로 땅을 차며 균형을 잡는 목제 두 바퀴 **라우프마시네**를 내놓으며 자전거 시대를 열었습니다.

            출처: Gillen D'Arcy Wood, Tambora (2014)
            """,
            deepDiveWithSource: """
            드라이스는 만하임 시연에서 13킬로미터를 1시간 이내에 주파해 우편 마차보다 빠른 속도를 증명했습니다.

            페달이 추가되기까지는 약 40년이 더 걸렸지만, 두 바퀴를 일렬로 세워 균형을 잡는 발상은 대흉년이 강요한 혁신이었습니다.

            출처: Hans-Erhard Lessing, Automobilität: Karl Drais (2003)
            """
        ),
        GuestStaticPost(
            id: "babylon-copper-complaint",
            categoryId: "history",
            title: "인류 최고(最古)의 고객 불만 문서는 3,750년 전 점토판",
            tags: ["역사", "메소포타미아", "문화"],
            bodyWithSource: """
            기원전 **1750년**경 우르에 살던 구매자 난니는 구리 상인 **에아-나시르**에게 쐐기문자로 항의 점토판을 보냈습니다. 납품한 구리 품질이 형편없고 심부름꾼을 모욕했다는 내용이었습니다.

            고고학자들이 이 점토판을 발굴한 곳은 뜻밖에도 *에아-나시르 자신의 집*—다른 불만 고객들의 점토판 더미와 함께 보관되어 있었습니다.

            출처: British Museum Collection, U.16800 (Ur Excavations)
            """,
            deepDiveWithSource: """
            아카드어 쐐기문자로 적힌 글에서 난니는 *"나를 누구로 보고 감히 이토록 무례히 대하는가"*라며 대금 반환을 요구합니다.

            레너드 울리의 발굴로 항의 편지 수집가 같은 면모가 드러나면서, 이 청동기 시대 상인은 오늘날 별점 1개 후기의 상징이 되었습니다.

            출처: A. Leo Oppenheim, Letters from Mesopotamia (1967)
            """
        ),
        GuestStaticPost(
            id: "nintendo-1889",
            categoryId: "history",
            title: "닌텐도는 에펠탑이 개장한 같은 해에 창립되었다",
            tags: ["역사", "게임", "일본"],
            bodyWithSource: """
            마리오나 닌텐도 스위치보다 훨씬 앞서, 야마우치 후사지로가 교토에 **닌텐도 골패**를 세운 해는 **1889년 9월**—파리에 에펠탑이 개장한 지 불과 몇 달 뒤였습니다.

            회사는 70년 넘게 닥나무 껍질 종이에 손으로 그린 전통 *하나후다(화투)* 카드를 팔며 명맥을 이었습니다.

            출처: Florent Gorges, The History of Nintendo 1889–1980 (2012)
            """,
            deepDiveWithSource: """
            메이지 시대 도박 규제로 숫자 카드가 단속되던 시기, 계절 꽃을 그린 하나후다 카드는 교토에서 선풍적인 인기를 끌었습니다.

            1949년 손자 야마우치 히로시가 가업을 이은 뒤 디즈니 플라스틱 카드와 다양한 사업 실험을 거쳐 요코이 군페이의 게임 & 워치로 디지털 시대를 열었습니다.

            출처: David Sheff, Game Over (1993)
            """
        ),
        GuestStaticPost(
            id: "sharks-older-than-trees",
            categoryId: "science",
            title: "상어는 나무보다도, 토성의 고리보다도 오래되었다",
            tags: ["과학", "자연", "연대기"],
            bodyWithSource: """
            상어 비늘 화석은 약 **4억 5,000만 년 전** 오르도비스기 바다까지 거슬러 올라갑니다. 육지에 첫 나무가 뿌리내리기보다 약 *9,000만 년* 앞선 시기입니다.

            카시니 탐사선 관측에 따르면 토성의 얼음 고리는 **1,000만~1억 년** 정도로 추정되어, 상어가 토성의 고리보다 최소 *4배*는 더 오래 존재했습니다.

            출처: Luciano Iess et al., Science (2019) & Ivanov et al., Paleobiology
            """,
            deepDiveWithSource: """
            상어는 해양 생물의 80% 이상이 사라진 페름기-트라이아스기 대멸종을 포함해 지구의 5대 대멸종을 모두 견뎌 냈습니다.

            반면 카시니의 중력·우주먼지 측정 결과는 토성의 밝은 고리가 지질학적으로 매우 최근에 형성되었음을 가리켰습니다.

            출처: Sascha Kempf et al., Science Advances (2023)
            """
        ),
        GuestStaticPost(
            id: "mario-mustache-pixels",
            categoryId: "design",
            title: "마리오가 모자와 멜빵바지, 콧수염을 갖게 된 이유",
            tags: ["디자인", "게임", "도트"],
            bodyWithSource: """
            **1981년** 〈동키콩〉을 제작하던 미야모토 시게루에게 주어진 캔버스는 단 **16×16 픽셀** 격자와 캐릭터당 세 가지 색상뿐이었습니다.

            머리카락 움직임을 그릴 수 없어 **모자**를 씌웠고, 팔 동작을 몸통과 구분하려 **붉은 멜빵바지**를 입혔으며, 입 없이 코와 얼굴을 구분하려고 굵은 **콧수염**을 붙였습니다.

            출처: Shigeru Miyamoto, Iwata Asks: New Super Mario Bros. Wii (2009)
            """,
            deepDiveWithSource: """
            초기 브라운관 모니터에서는 60Hz 화면 전환 시 미세한 선이 번져 사라졌기 때문에 단번에 읽히는 실루엣이 필수였습니다.

            256개의 작은 픽셀 제약이 낳은 디자인이 반세기 가까이 사랑받는 아이콘으로 남았습니다.

            출처: Chris Kohler, Power-Up (2004)
            """
        ),
        GuestStaticPost(
            id: "pigeons-monet-picasso",
            categoryId: "science",
            title: "비둘기에게 모네와 피카소 그림 구별을 가르친 연구",
            tags: ["과학", "예술", "심리학"],
            bodyWithSource: """
            **1995년** 게이오대학의 와타나베 시게루 교수는 먹이 보상을 통해 비둘기들이 **모네**와 **피카소**의 회화를 구별하도록 훈련했습니다.

            새들은 *한 번도 본 적 없는* 작품이나 거꾸로 뒤집은 흑백 인쇄물 앞에서도 인상주의와 입체주의를 **90% 이상 정확도**로 구분해 이그노벨상을 받았습니다.

            출처: Shigeru Watanabe et al., JEAB (1995)
            """,
            deepDiveWithSource: """
            단순 암기 여부를 검증하려 다른 화가 그림을 제시하자 모네 그룹 비둘기는 르누아르와 세잔을, 피카소 그룹은 브라크와 마티스를 정확히 묶어 냈습니다.

            4원색 시각을 지닌 조류 역시 추상적 화풍의 패턴을 일반화할 수 있음을 보여준 실험입니다.

            출처: Shigeru Watanabe, Animal Cognition (2001)
            """
        ),
        GuestStaticPost(
            id: "chess-more-than-atoms",
            categoryId: "science",
            title: "체스의 가능한 게임 수는 우주의 원자 수보다 많다",
            tags: ["과학", "수학", "문화"],
            bodyWithSource: """
            정보이론의 창시자 **클로드 섀넌**은 1950년 합법적인 체스 게임의 보수적 하한선을 **10¹²⁰가지**(*섀넌 수*)로 계산했습니다.

            관측 가능한 우주 전체의 원자 수는 약 **10⁸⁰개**로 추정되므로, 초반 몇 수만 두어도 체스판의 경우의 수는 우주의 입자 수를 훌쩍 넘깁니다.

            출처: Claude E. Shannon, Philosophical Magazine (1950)
            """,
            deepDiveWithSource: """
            백과 흑이 한 수씩만 두어도 400가지, 세 수씩 두면 1억 2,100만 개가 넘는 경로가 펼쳐집니다. 섀넌은 평균 40수, 턴당 약 30개 합법 수를 기준으로 (10³)^40 = 10¹²⁰을 산출했습니다.

            현대 분석에서도 도달 가능한 체스 국면 수 자체가 10⁴⁴을 상회하는 것으로 확인됩니다.

            출처: John Tromp & Stefan Edelkamp, Chess Game Complexity (2022)
            """
        )
    ]
}
