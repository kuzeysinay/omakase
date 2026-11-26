//
//  GuestStaticCatalog.swift
//  omakase
//
//  Curated 8-story static pool (all 7 languages, verified primary sources)
//  used by GuestTasteView to randomly pick and live-stream 2 authentic plates
//  before requiring sign-up.
//

import Foundation

struct GuestStaticPost: Identifiable, Sendable {
    let id: String
    let categoryId: String
    let title: String
    let tags: [String]
    let bodyWithSource: String
    let deepDiveWithSource: String

    private static let shownIDsStorageKey = "omakase.guestShownPostIDs"

    static func pickRandomTwo(for language: AppLanguage) -> [GuestStaticPost] {
        let pool = posts(for: language)
        var shown = UserDefaults.standard.stringArray(forKey: shownIDsStorageKey) ?? []
        var unseen = pool.filter { !shown.contains($0.id) }

        if unseen.count < 2 {
            // Reset history once exhausted, but still exclude the most recently shown pair
            // so back-to-back sessions never repeat the same stories.
            let lastPair = Array(shown.suffix(2))
            unseen = pool.filter { !lastPair.contains($0.id) }
            if unseen.count < 2 {
                unseen = pool
            }
            shown = lastPair
        }

        let picked = Array(unseen.shuffled().prefix(2))
        shown.append(contentsOf: picked.map(\.id))
        UserDefaults.standard.set(shown, forKey: shownIDsStorageKey)
        return picked
    }

    static func posts(for language: AppLanguage) -> [GuestStaticPost] {
        let base: [GuestStaticPost]
        switch language {
        case .turkish: base = turkishPosts
        case .japanese: base = japanesePosts
        case .german: base = germanPosts
        case .french: base = frenchPosts
        case .spanish: base = spanishPosts
        case .korean: base = koreanPosts
        case .english: base = englishPosts
        }
        return base + extraPosts(for: language)
    }

    // MARK: - English (8 Stories)

    private static let englishPosts: [GuestStaticPost] = [
        GuestStaticPost(
            id: "oxford-aztec",
            categoryId: "history",
            title: "Oxford University Is Older Than the Aztec Empire",
            tags: ["History", "Timelines", "Culture"],
            bodyWithSource: """
            Lectures were already echoing through Oxford by **1096**, and formal colleges existed by 1249—more than *two centuries before* the Aztecs founded Tenochtitlan in 1325.

            By the time the Aztec Empire formed in **1428**, Oxford had been graduating scholars for over 300 years. History's timelines overlap in ways school textbooks rarely make feel real.

            Source: L. W. B. Brockliss, The University of Oxford: A History (2016)
            """,
            deepDiveWithSource: """
            When the Aztec Triple Alliance united the Valley of Mexico in 1428, Oxford's oldest library was already expanding—and Machu Picchu wouldn't even be built for another twenty years.

            Our mental timeline treats medieval Europe and Mesoamerica as separate eras, yet they overlapped for generations. Earlier still, al-Qarawiyyin in Fez (859) and Bologna (1088) were already teaching students across continents, proving how compressed our historical memory really is.

            Source: Michael E. Smith, The Aztecs (2012)
            """
        ),
        GuestStaticPost(
            id: "stradivarius-ice-age",
            categoryId: "music",
            title: "How a Mini Ice Age Built the Stradivarius Sound",
            tags: ["Music", "Climate", "Craft"],
            bodyWithSource: """
            Between 1645 and 1715, sunspots nearly vanished and Europe froze through the **Maunder Minimum**. Alpine spruce trees grew agonizingly slowly, packing razor-thin, hyper-dense growth rings into every centimeter.

            Antonio Stradivari carved his golden-period violins from that exact *climate-compressed wood*. Dendrochronologists proved in 2003 the secret wasn't varnish—it was winter frozen into the grain.

            Source: Henri Grissino-Mayer & Lloyd Burckle, Dendrochronologia (2003)
            """,
            deepDiveWithSource: """
            During the coldest decades of Europe's Little Ice Age, shorter summers forced spruce trees in the Italian Alps to produce remarkably uniform earlywood and latewood cells. That accidental acoustic engineering gave sound waves faster propagation and lower damping inside the violin's top plate.

            In 2008, Swiss researcher Francis Schwarze tested the density theory directly by treating modern spruce and maple with selective wood-decay fungi. In blind listening tests, musicians mistook his bio-engineered violin for an authentic 1711 Stradivarius.

            Source: Francis W. M. R. Schwarze et al., New Phytologist (2008)
            """
        ),
        GuestStaticPost(
            id: "kurosawa-ink-rain",
            categoryId: "film",
            title: "Why Kurosawa Poured Black Ink Into the Rain",
            tags: ["Cinema", "Craft", "Directing"],
            bodyWithSource: """
            While filming *Rashomon* in **1950**, Akira Kurosawa noticed real rain vanished against the bright sky on black-and-white film stock.

            His fix was pure visual alchemy: he ordered the crew to mix **black calligraphy ink** into water pumped from fire engines, turning invisible drizzle into razor-sharp streaks on screen.

            Source: Donald Richie, The Films of Akira Kurosawa (1965)
            """,
            deepDiveWithSource: """
            Monochrome film captures luminance rather than hue, so clear water droplets simply reflect the ambient sky and disappear. Kurosawa didn't just darken the rain—he staged towering backlit silhouettes and hung crisp dark backdrops behind the ruined Rashomon gate so every falling drop read like brushstrokes.

            That obsession with weather as emotional architecture carried straight into *Seven Samurai* (1954), where mud and freezing downpours stripped away romantic samurai tropes and made physical exhaustion visible in every frame.

            Source: Akira Kurosawa, Something Like an Autobiography (1982)
            """
        ),
        GuestStaticPost(
            id: "roman-concrete",
            categoryId: "science",
            title: "Why Ancient Roman Concrete Heals Its Own Cracks",
            tags: ["Science", "Architecture", "Materials"],
            bodyWithSource: """
            Modern Portland cement piers crumble within decades in seawater, yet **2,000-year-old** Roman harbors still stand intact.

            In 2023, MIT researchers discovered the white mineral flecks inside Roman concrete aren't mixing errors—they are **hot-mixed quicklime clasts** that react with entering water to recrystallize and seal fresh cracks automatically.

            Source: Admir Masic et al., Science Advances (2023)
            """,
            deepDiveWithSource: """
            For decades engineers assumed Roman builders simply failed to stir their mortar evenly. By pairing high-resolution X-ray imaging with Roman architectural texts, Admir Masic's team showed builders deliberately mixed volcanic ash with unslaked quicklime at scorching temperatures.

            When seawater seeps into a hairline fracture, those calcium-rich clasts dissolve and precipitate fresh calcite crystals that bridge the gap before steel-free masonry can split—turning erosion into a self-repair trigger.

            Source: Linda M. Seymour et al., Science Advances (2023)
            """
        ),
        GuestStaticPost(
            id: "1904-marathon",
            categoryId: "sports",
            title: "The Most Chaotic Marathon in Olympic History",
            tags: ["Sports", "History", "Olympics"],
            bodyWithSource: """
            The **1904 St. Louis Olympic marathon** had 32 starters, dusty unpaved roads, only one water well at mile 12, and a runner who chased wild dogs a mile off course.

            Winner Thomas Hicks survived on *rat poison (strychnine) and brandy* administered mid-race by his trainers—and was carried across the finish line.

            Source: David E. Martin & Roger W. H. Gynn, The Olympic Marathon (2000)
            """,
            deepDiveWithSource: """
            Organizers scheduled the race for 3:00 PM in 32°C Missouri humidity and drove lead cars ahead of the runners, kicking up suffocating clouds of dust. Cuba's Félix Carvajal ran in street trousers cut short at the knees and stopped for apples—only to suffer cramps from rotten ones.

            Meanwhile, Fred Lorz hitched an eleven-mile car ride until it broke down, jogged across the finish line first as a joke, and was briefly hailed as champion before officials stripped the medal and awarded it to a hallucinating Hicks.

            Source: Charles J. P. Lucas, The Olympic Games 1904 (1905)
            """
        ),
        GuestStaticPost(
            id: "tokyo-station-melodies",
            categoryId: "travel",
            title: "Why Tokyo's Train Platforms Play 7-Second Melodies",
            tags: ["Design", "Travel", "Music"],
            bodyWithSource: """
            Step onto Tokyo's Yamanote Line and instead of harsh buzzers, each platform plays a bespoke **7-second melody** (*hassha merodī*).

            Sound designers composed distinct chimes per station so sleepy commuters instantly recognize stops by ear and feel *measurably less urgency* to sprint for closing doors.

            Source: Minoru Mukaiya, Ongakukan Sound Archives (2012)
            """,
            deepDiveWithSource: """
            Before 1989, Japanese National Railways relied on piercing electric bells that spiked commuter cortisol and triggered dangerous last-second dashes onto crowded cars. East Japan Railway partnered with acoustic psychologists and musician Minoru Mukaiya to replace alarms with soft, major-key motifs.

            Stations chose melodies tied to local heritage—Takadanobaba plays the *Astro Boy* theme where creator Osamu Tezuka worked, while Ebisu rings out *The Third Man* theme—turning daily transit into calm spatial wayfinding.

            Source: East Japan Railway Culture Foundation Archives (2010)
            """
        ),
        GuestStaticPost(
            id: "xray-jazz",
            categoryId: "art",
            title: "When Jazz Bootleggers Etched Records Onto X-Rays",
            tags: ["Music", "History", "Culture"],
            bodyWithSource: """
            When jazz and Western rock were banned in **1950s Leningrad**, underground audio engineers needed cheap discs to press contraband music.

            They raided hospital dumpsters for **discarded X-ray films**, trimmed them into circles with manicure scissors, burned a spindle hole with a cigarette, and etched Miles Davis straight onto ribs and skulls.

            Source: Stephen Coates, X-Ray Audio (2015)
            """,
            deepDiveWithSource: """
            Known as *roentgenizdat*—"bone music"—each flexible X-ray sheet held one three-minute track at 78 rpm and wore out after roughly twenty plays. Bootleggers built homemade lathe cutters using salvaged gramophone parts and sold the translucent blue discs for a ruble in dark alleys.

            Although authorities raided studios and jailed key cutters like Ruslan Bogoslovsky, millions of ghostly X-ray records circulated across the Soviet Union, proving human curiosity routinely routes around censorship with whatever scrap material lies nearby.

            Source: Anya von Bremzen, Mastering the Art of Soviet Cooking (2013)
            """
        ),
        GuestStaticPost(
            id: "immortal-jellyfish",
            categoryId: "nature",
            title: "The Tiny Jellyfish That Resets Its Life Clock",
            tags: ["Nature", "Science", "Biology"],
            bodyWithSource: """
            Most animals age in one direction. *Turritopsis dohrnii*—no wider than a pinky nail—cheats the rule through **transdifferentiation**.

            When injured, starved, or stressed, the adult medusa sinks to the seafloor, absorbs its tentacles, and transforms back into a **juvenile polyp** ready to clone itself anew.

            Source: Stefano Piraino et al., Biological Bulletin (1996)
            """,
            deepDiveWithSource: """
            First documented in the 1980s by marine biologists Christian Sommer and Giorgio Bavestrello, the jellyfish doesn't merely pause aging—its specialized adult nerve and muscle cells literally rewrite their identities into stem-like polyp cells.

            Genomic sequencing in 2022 revealed *Turritopsis dohrnii* carries extra copies of DNA-repair and telomere-maintenance genes compared to mortal jellyfish relatives, offering geneticists rare clues into cellular reprogramming without tumor growth.

            Source: Maria Pascual-Torner et al., PNAS (2022)
            """
        )
    ]

    // MARK: - Turkish (8 Stories)

    private static let turkishPosts: [GuestStaticPost] = [
        GuestStaticPost(
            id: "oxford-aztec",
            categoryId: "history",
            title: "Oxford Üniversitesi, Aztek İmparatorluğu'ndan Daha Eski",
            tags: ["Tarih", "Zaman Çizelgesi", "Kültür"],
            bodyWithSource: """
            Oxford'da dersler **1096** yılında zaten başlamıştı; 1249'da ise ilk resmi kolejler kurulmuştu—Azteklerin Tenochtitlan'ı 1325'te kurmasından *iki yüzyıldan fazla* önce.

            **1428**'de Aztek İmparatorluğu şekillenirken Oxford 300 yılı aşkın süredir mezun veriyordu. Tarihin zaman çizgileri ders kitaplarının sandığından çok daha şaşırtıcı biçimde kesişir.

            Kaynak: L. W. B. Brockliss, The University of Oxford: A History (2016)
            """,
            deepDiveWithSource: """
            1428'de Aztek Üçlü İttifakı Meksika Vadisi'ni birleştirdiğinde, Oxford'un en eski kütüphanesi çoktan genişletiliyordu ve Machu Picchu'nun inşasına bile henüz yirmi yıl vardı.

            Zihnimiz Orta Çağ Avrupası ile Mezoamerika'yı birbirinden kopuk çağlar sanır; oysa nesiller boyu aynı güneşin altında yan yana yaşadılar. Daha da geriye gidersek Fas'taki Karaviyyin Üniversitesi (859) ve Bologna (1088), kıtalar arasında yüzyıllardır öğrenci yetiştiriyordu.

            Kaynak: Michael E. Smith, The Aztecs (2012)
            """
        ),
        GuestStaticPost(
            id: "stradivarius-ice-age",
            categoryId: "music",
            title: "Küçük Buzul Çağı Stradivarius Sesini Nasıl Yarattı?",
            tags: ["Müzik", "İklim", "Zanaat"],
            bodyWithSource: """
            1645 ile 1715 arasında güneş lekeleri neredeyse yok oldu ve Avrupa **Maunder Minimumu** soğuğuna gömüldü. Alpler'deki ladin ağaçları çok yavaş büyüyerek her santimetreye olağanüstü sıkı yaş halkaları sıkıştırdı.

            Antonio Stradivari altın dönem kemanlarını tam da bu *iklimle yoğunlaşmış ahşaptan* oydu; sır cilada değil, ağacın dokusuna hapsolmuş kıştaydı.

            Kaynak: Henri Grissino-Mayer & Lloyd Burckle, Dendrochronologia (2003)
            """,
            deepDiveWithSource: """
            Küçük Buzul Çağı'nın en sert on yıllarında kısa süren yazlar, İtalyan Alpleri'ndeki ladinlerin son derece homojen ve yoğun hücre duvarları örmesine yol açtı. Bu tesadüfi akustik mühendislik, ses dalgalarının kemanın göğüs tahtasında daha hızlı yayılmasını sağladı.

            2008'de İsviçreli araştırmacı Francis Schwarze, odun yiyen mantarlarla modern ladin ve akçaağacı kontrollü biçimde işleyerek benzer hücresel yoğunluğu laboratuvarda üretti. Kör dinleme testinde uzmanlar bu kemanı 1711 yapımı gerçek bir Stradivarius sandı.

            Kaynak: Francis W. M. R. Schwarze et al., New Phytologist (2008)
            """
        ),
        GuestStaticPost(
            id: "kurosawa-ink-rain",
            categoryId: "film",
            title: "Kurosawa Yağmura Neden Siyah Mürekkep Karıştırdı?",
            tags: ["Sinema", "Kurgu", "Yönetmenlik"],
            bodyWithSource: """
            Akira Kurosawa **1950** yapımı *Rashomon* filmini çekerken, gerçek yağmurun siyah-beyaz film şeridinde gökyüzüne karışıp tamamen kaybolduğunu fark etti.

            Çözümü saf bir görsel simyaydı: Setteki itfaiye pompalarının suyuna **siyah kaligrafi mürekkebi** karıştırtarak görünmez çiselemeyi ekranda jilet gibi keskin çizgilere dönüştürdü.

            Kaynak: Donald Richie, The Films of Akira Kurosawa (1965)
            """,
            deepDiveWithSource: """
            Siyah-beyaz film rengi değil yalnızca ışık şiddetini yakalar; şeffaf su damlaları gökyüzünü yansıttığı için kadrajda erir. Kurosawa yalnızca suyu boyamakla kalmadı, yıkık Rashomon kapısının arkasına koyu fonlar gererek ve ters ışık kullanarak her damlayı fırça darbesine çevirdi.

            Hava koşullarını duygusal bir karaktere dönüştürme tutkusu, çamurun ve dondurucu sağanağın samuray romantizmini parçaladığı *Yedi Samuray* (1954) filminde zirveye çıktı.

            Kaynak: Akira Kurosawa, Something Like an Autobiography (1982)
            """
        ),
        GuestStaticPost(
            id: "roman-concrete",
            categoryId: "science",
            title: "Roma Betonu Çatlaklarını Kendi Kendine Nasıl Onarır?",
            tags: ["Bilim", "Mimari", "Malzeme"],
            bodyWithSource: """
            Modern Portland çimentosu deniz suyunda birkaç on yılda ufalanırken, **2.000 yıllık** Roma limanları hâlâ sapasağlam ayakta.

            2023'te MIT araştırmacıları, Roma betonundaki beyaz mineral parçacıklarının karışım hatası değil, sızan suyla tepkimeye girip çatlağı taze kalsitle mühürleyen **sıcak karıştırılmış sönmemiş kireç** olduğunu keşfetti.

            Kaynak: Admir Masic et al., Science Advances (2023)
            """,
            deepDiveWithSource: """
            On yıllarca mühendisler Romalı ustaların harcı iyi karıştıramadığını sandı. Yüksek çözünürlüklü X-ışını görüntülemeyi antik mimari metinlerle birleştiren Admir Masic'in ekibi, ustaların volkanik külü yüksek sıcaklıkta sönmemiş kireçle bilerek harmanladığını kanıtladı.

            Betonda kılcal bir çatlak oluşup deniz suyu içeri sızdığında, bu kalsiyum yüklü parçacıklar çözünerek boşluğu dolduran yeni kalsit kristalleri üretir ve aşınmayı kendi kendini onaran bir tetikleyiciye dönüştürür.

            Kaynak: Linda M. Seymour et al., Science Advances (2023)
            """
        ),
        GuestStaticPost(
            id: "1904-marathon",
            categoryId: "sports",
            title: "Olimpiyat Tarihinin En Kaotik Maratonu",
            tags: ["Spor", "Tarih", "Olimpiyat"],
            bodyWithSource: """
            **1904 St. Louis Olimpiyat maratonu** 32 atlet, tozlu toprak yollar, 19. kilometrede tek bir su kuyusu ve vahşi köpeklerin parkurdan 1,5 kilometre kovaladığı bir koşucuya sahne oldu.

            Kazanan Thomas Hicks, antrenörlerinin yarış ortasında verdiği *fare zehri (striknin) ve konyakla* ayakta kalıp bitiş çizgisinden kollarında taşındı.

            Kaynak: David E. Martin & Roger W. H. Gynn, The Olympic Marathon (2000)
            """,
            deepDiveWithSource: """
            Organizatörler yarışı 32°C Missouri sıcağında saat 15.00'e koymuş ve öndeki araçların kaldırdığı toz bulutları atletlerin nefesini kesmişti. Kübalı postacı Félix Carvajal dizlerinden kestiği sokak pantolonuyla koşarken açlıktan yediği çürük elmalar yüzünden midesi kramp girince yol kenarında uyuyakaldı.

            Fred Lorz ise kramp girince 17 kilometreyi arabayla gidip şaka olsun diye bitişi ilk sırada geçti; gerçek ortaya çıkınca madalya halüsinasyonlar gören Hicks'e verildi.

            Kaynak: Charles J. P. Lucas, The Olympic Games 1904 (1905)
            """
        ),
        GuestStaticPost(
            id: "tokyo-station-melodies",
            categoryId: "travel",
            title: "Tokyo İstasyonları Neden 7 Saniyelik Melodiler Çalar?",
            tags: ["Tasarım", "Seyahat", "Müzik"],
            bodyWithSource: """
            Tokyo'nun Yamanote hattına indiğinizde sert ziller yerine her peron kendine özgü **7 saniyelik bir melodi** (*hassha merodī*) çalar.

            Ses tasarımcıları, uykulu yolcuların durağı kulaktan tanıması ve kapanan kapılara *koşma stresinin ölçülebilir biçimde azalması* için istasyon başına özgün besteler yazdı.

            Kaynak: Minoru Mukaiya, Ongakukan Ses Arşivi (2012)
            """,
            deepDiveWithSource: """
            1989 öncesinde Japon Demiryolları, yolcuların kortizol seviyesini fırlatan ve tehlikeli son saniye koşularına yol açan tiz elektrik zilleri kullanıyordu. JR East, akustik psikologlar ve müzisyen Minoru Mukaiya ile çalışarak alarmları yumuşak majör tonlu kısa motiflerle değiştirdi.

            İstasyonlar mahalle kimliğini yansıtan ezgiler seçti: Takadanobaba'da Osamu Tezuka'nın anısına *Astro Boy* teması, Ebisu'da ise *The Third Man* melodisi çalarak günlük ulaşımı sakin bir yön bulma deneyimine dönüştürdü.

            Kaynak: East Japan Railway Culture Foundation Arşivi (2010)
            """
        ),
        GuestStaticPost(
            id: "xray-jazz",
            categoryId: "art",
            title: "Leningrad'da Röntgen Filmlerine Kazınan Caz Plakları",
            tags: ["Müzik", "Tarih", "Kültür"],
            bodyWithSource: """
            **1950'lerin Leningrad'ında** caz ve Batı müziği yasaklanınca, yeraltı ses mühendisleri kaçak plak basmak için ucuz malzeme arayışına girdi.

            Hastane çöplüklerinden **atılmış röntgen filmleri** toplayıp manikür makasıyla daire kestiler, ortasını sigarayla delip kaburga ve kafatası görüntülerinin üstüne Miles Davis kazıdılar.

            Kaynak: Stephen Coates, X-Ray Audio (2015)
            """,
            deepDiveWithSource: """
            "Kemik müziği" (*roentgenizdat*) denen bu esnek röntgen plakları 78 devirde üç dakikalık tek bir parça taşıyor ve yaklaşık yirmi çalmadan sonra aşınıyordu. Kaçakçılar hurda gramofon parçalarından kendi kesim torna makinelerini kurup saydam mavi plakları karanlık sokaklarda bir rubleye sattı.

            Yetkililer stüdyoları basıp Ruslan Bogoslovsky gibi öncüleri hapse atsa da milyonlarca hayalet röntgen plak tüm Sovyetler Birliği'ne yayıldı ve merakın sansürü nasıl aştığını kanıtladı.

            Kaynak: Anya von Bremzen, Mastering the Art of Soviet Cooking (2013)
            """
        ),
        GuestStaticPost(
            id: "immortal-jellyfish",
            categoryId: "nature",
            title: "Yaşam Saatini Çocukluğa Geri Saran Minik Denizanası",
            tags: ["Doğa", "Bilim", "Biyoloji"],
            bodyWithSource: """
            Neredeyse tüm canlılar tek yönde yaşlanır. Serçe parmak tırnağı kadar küçük *Turritopsis dohrnii* ise **transdiferansiyasyon** sayesinde bu kuralı bozar.

            Yaralandığında veya aç kaldığında yetişkin denizanası deniz tabanına çöker, dokunaçlarını eritir ve yeniden **genç bir polip** evresine dönerek kendini klonlamaya başlar.

            Kaynak: Stefano Piraino et al., Biological Bulletin (1996)
            """,
            deepDiveWithSource: """
            1980'lerde deniz biyologları Christian Sommer ve Giorgio Bavestrello tarafından belgelenen bu süreçte denizanası yalnızca yaşlanmayı durdurmaz; özelleşmiş yetişkin sinir ve kas hücreleri kimliklerini sıfırlayıp yeniden kök hücre benzeri polip dokusuna dönüşür.

            2022'deki genom dizilimi, *Turritopsis dohrnii*'nin ölümlü akrabalarına kıyasla DNA onarımı ve telomer koruma genlerinden fazladan kopyalar taşıdığını ortaya çıkardı; bu da kanserleşmeden hücresel yenilenme araştırmalarına ışık tutuyor.

            Kaynak: Maria Pascual-Torner et al., PNAS (2022)
            """
        )
    ]

    // MARK: - Japanese (8 Stories)

    private static let japanesePosts: [GuestStaticPost] = [
        GuestStaticPost(
            id: "oxford-aztec",
            categoryId: "history",
            title: "オックスフォード大学はアステカ帝国より古い",
            tags: ["歴史", "年表", "教養"],
            bodyWithSource: """
            オックスフォードで講義が始まったのは**1096年**ごろ。アステカ人がテノチティトランを建都した1325年より*2世紀以上も前*のことでした。

            アステカ帝国が成立した**1428年**には、オックスフォードはすでに300年以上の歴史を誇っていたのです。年表を並べてみると、歴史の感覚は一気に塗り替わります。

            出典: L. W. B. Brockliss, The University of Oxford: A History (2016)
            """,
            deepDiveWithSource: """
            1428年にアステカ三国同盟が誕生した頃、オックスフォードではすでに図書館の拡張が進んでおり、マチュピチュはまだ着工すらされていませんでした。

            私たちは中世ヨーロッパとメソアメリカを別の時代のように捉えがちですが、実際には何世代にもわたって同じ時代を並走していました。さらに遡れば、フェズのカラウィーイーン大学（859年）やボローニャ大学（1088年）もそれ以前から学問を紡いでいました。

            出典: Michael E. Smith, The Aztecs (2012)
            """
        ),
        GuestStaticPost(
            id: "stradivarius-ice-age",
            categoryId: "music",
            title: "小氷期が生んだストラディバリウスの響き",
            tags: ["音楽", "気候", "工芸"],
            bodyWithSource: """
            1645年から1715年にかけて太陽黒点が激減し、欧州は**マウンダー極小期**の厳冬に包まれました。アルプスのトウヒは極端にゆっくり育ち、年輪が緻密に詰まった高密度な木材になったのです。

            ストラディバリが黄金期の名器を削り出したのは、まさにその*厳冬が圧縮した木*でした。

            出典: Henri Grissino-Mayer & Lloyd Burckle, Dendrochronologia (2003)
            """,
            deepDiveWithSource: """
            小氷期の最も寒冷な数十年、短い夏によってイタリア・アルプスのトウヒは極めて均質で密な細胞構造を形成しました。この偶然の音響工学が、表板の振動伝達速度を高め、減衰を抑えたのです。

            2008年、スイスの研究者フランシス・シュヴァルツェは特定の菌類で木材の細胞密度を整えることに成功しました。盲検テストでは、熟練の演奏家さえ1711年製ストラディバリウスと聴き分けられなかったと報告されています。

            出典: Francis W. M. R. Schwarze et al., New Phytologist (2008)
            """
        ),
        GuestStaticPost(
            id: "kurosawa-ink-rain",
            categoryId: "film",
            title: "黒澤明『羅生門』の雨に墨汁を混ぜた理由",
            tags: ["映画", "演出", "撮影"],
            bodyWithSource: """
            **1950年**に『羅生門』を撮影中、黒澤明は本物の雨が白黒フィルムの明るい空に溶け込んでほとんど映らないことに気づきました。

            そこで彼は消防ポンプで降らせる水に**黒い墨汁**を混ぜさせ、見えない小雨をスクリーン上で鋭い一筋の線へと変えたのです。

            出典: Donald Richie, The Films of Akira Kurosawa (1965)
            """,
            deepDiveWithSource: """
            白黒フィルムは色ではなく輝度を記録するため、透明な水滴は空の光を反射して背景に消えてしまいます。黒澤は水を黒く染めただけでなく、羅生門セットの背後に暗い背景幕と逆光を配置し、一粒一粒を日本画の筆致のように際立たせました。

            天候を登場人物の感情へと織り込むこの執念は、泥と豪雨が侍のロマンを剥ぎ取る『七人の侍』（1954年）で頂点に達します。

            出典: 黒澤明『蝦蟇の油 自伝のようなもの』(1982)
            """
        ),
        GuestStaticPost(
            id: "roman-concrete",
            categoryId: "science",
            title: "自己修復する古代ローマのコンクリート",
            tags: ["科学", "建築", "素材"],
            bodyWithSource: """
            現代のポルトランドセメントが海水で数十年で劣化するのに対し、**2,000年前**のローマ港湾遺構は今なお堅牢です。

            2023年、MITの研究チームはコンクリート内の白い粒が混ぜムラではなく、侵入した水と反応してひび割れを新しい方解石で塞ぐ**高温混合の生石灰**だと突き止めました。

            出典: Admir Masic et al., Science Advances (2023)
            """,
            deepDiveWithSource: """
            長らく技術者たちは古代ローマの職人がモルタルを十分に攪拌できなかっただけだと考えていました。しかし高精細X線解析と古代の建築書を照合した研究により、火山灰と生石灰をあえて高温で練り混ぜていたことが判明しました。

            海水が微細な亀裂から入り込むと、カルシウムを豊富に含む石灰粒が溶けて再結晶し、構造が割れる前にひびを自ら修復します。

            出典: Linda M. Seymour et al., Science Advances (2023)
            """
        ),
        GuestStaticPost(
            id: "1904-marathon",
            categoryId: "sports",
            title: "五輪史上もっとも混沌とした1904年マラソン",
            tags: ["スポーツ", "歴史", "五輪"],
            bodyWithSource: """
            **1904年セントルイス五輪マラソン**は32名が未舗装の砂埃の中を走り、給水所は19km地点に1つだけ、野犬に1.5kmも追いかけられた選手までいました。

            優勝したトーマス・ヒックスは、コーチが途中で飲ませた*ストリキニーネ（殺鼠剤）とブランデー*に支えられ、抱えられてゴールしました。

            出典: David E. Martin & Roger W. H. Gynn, The Olympic Marathon (2000)
            """,
            deepDiveWithSource: """
            大会側は気温32度の午後3時に競技を開始し、先導車が巻き上げる砂埃で選手たちは呼吸困難に陥りました。キューバの郵便配達員フェリックス・カルバハルは街着のズボンを膝で切って走り、空腹で食べた傷んだリンゴの腹痛で道端に寝込んでしまいました。

            さらにフレッド・ローツは途中で17kmも車に乗ってジョークで1着ゴールし、後に失格となって幻覚状態のヒックスに金メダルが贈られました。

            出典: Charles J. P. Lucas, The Olympic Games 1904 (1905)
            """
        ),
        GuestStaticPost(
            id: "tokyo-station-melodies",
            categoryId: "travel",
            title: "東京の発車メロディが7秒間の音楽である理由",
            tags: ["デザイン", "旅", "音楽"],
            bodyWithSource: """
            東京の山手線ホームでは甲高いベルの代わりに、駅ごとに異なる**7秒間の発車メロディ**が流れます。

            眠気眼の乗客が音だけで駅を判別でき、閉まるドアへ*駆け込む焦りを和らげる*よう音響心理学者と作曲家が設計しました。

            出典: 向谷実 音楽館サウンドアーカイブ (2012)
            """,
            deepDiveWithSource: """
            1989年以前の鉄道駅では鋭い電鈴が鳴り響き、通勤客の緊張感を高めて危険な駆け込み乗車を誘発していました。JR東日本は音楽家の向谷実らと組み、警報音を柔らかな長調のフレーズへと置き換えました。

            手塚治虫ゆかりの高田馬場では『鉄腕アトム』、恵比寿では『第三の男』が流れるなど、地域文化を映す音風景が都市の案内役を担っています。

            出典: 東日本鉄道文化財団アーカイブ (2010)
            """
        ),
        GuestStaticPost(
            id: "xray-jazz",
            categoryId: "art",
            title: "レントゲン写真に刻まれた禁断のジャズレコード",
            tags: ["音楽", "歴史", "文化"],
            bodyWithSource: """
            **1950年代のレニングラード**でジャズや西洋ロックが禁じられたとき、地下の録音技師たちは安価なレコード盤の代用品を探していました。

            彼らは病院の廃棄場から**使用済みX線フィルム**を回収し、ハサミで丸く切り抜き、タバコで中心穴を開けて肋骨や頭蓋骨の上にマイルス・デイヴィスを刻みました。

            出典: Stephen Coates, X-Ray Audio (2015)
            """,
            deepDiveWithSource: """
            「骨の音楽（レントゲニズダート）」と呼ばれたこの薄い盤は、78回転で3分間の1曲を収録でき、約20回再生すると摩耗しました。密造者たちは蓄音機の部品で自作のカッティングマシンを組み上げ、半透明の青い盤を路地裏で1ルーブルで売りました。

            当局の摘発を受けながらも数百万枚のX線レコードがソ連全土を巡り、好奇心がどれほど軽やかに検閲をすり抜けるかを物語っています。

            出典: Anya von Bremzen, Mastering the Art of Soviet Cooking (2013)
            """
        ),
        GuestStaticPost(
            id: "immortal-jellyfish",
            categoryId: "nature",
            title: "命の時計を幼年期へ巻き戻す小さなクラゲ",
            tags: ["自然", "科学", "生物学"],
            bodyWithSource: """
            ほとんどの動物は一方向に年を重ねます。しかし小指の爪より小さい**ベニクラゲ**（*Turritopsis dohrnii*）は**分化転換**によってその法則を覆します。

            傷ついたり飢えたりすると、成体のクラゲは海底に沈んで触手を吸収し、再びクローンを増やす**ポリプ期**へと若返るのです。

            出典: Stefano Piraino et al., Biological Bulletin (1996)
            """,
            deepDiveWithSource: """
            1980年代に海洋生物学者クリスティアン・ゾンマーとジョルジョ・バヴェストレッロが発見したこの現象は、単なる老化の停止ではありません。すでに分化した神経細胞や筋肉細胞が役割を書き換え、幹細胞のようなポリプ細胞へと戻るのです。

            2022年のゲノム解読により、ベニクラゲは近縁のクラゲよりもDNA修復やテロメア維持に関わる遺伝子を多く持つことが判明し、細胞初期化の研究に新たな手がかりを与えています。

            出典: Maria Pascual-Torner et al., PNAS (2022)
            """
        )
    ]

    // MARK: - German (8 Stories)

    private static let germanPosts: [GuestStaticPost] = [
        GuestStaticPost(
            id: "oxford-aztec",
            categoryId: "history",
            title: "Die Universität Oxford ist älter als das Aztekenreich",
            tags: ["Geschichte", "Zeitleiste", "Kultur"],
            bodyWithSource: """
            In Oxford wurde bereits um **1096** gelehrt – mehr als *zwei Jahrhunderte bevor* die Azteken 1325 ihre Hauptstadt Tenochtitlán gründeten.

            Als das Aztekenreich **1428** entstand, blickte Oxford schon auf über 300 Jahre Universitätsgeschichte zurück. Zeitachsen überlappen sich oft ganz anders, als unser Gefühl vermutet.

            Quelle: L. W. B. Brockliss, The University of Oxford: A History (2016)
            """,
            deepDiveWithSource: """
            Als sich 1428 der aztekische Dreibund formte, wuchs Oxfords älteste Bibliothek bereits rasant – und Machu Picchu sollte erst zwanzig Jahre später erbaut werden.

            Unser Geschichtsgefühl trennt das europäische Mittelalter und Mesoamerika wie getrennte Welten, obwohl sie jahrhundertelang gleichzeitig existierten. Noch früher lehrten bereits al-Qarawiyyin in Fès (859) und Bologna (1088) Generationen von Gelehrten.

            Quelle: Michael E. Smith, The Aztecs (2012)
            """
        ),
        GuestStaticPost(
            id: "stradivarius-ice-age",
            categoryId: "music",
            title: "Wie eine Kleine Eiszeit den Stradivari-Klang schuf",
            tags: ["Musik", "Klima", "Handwerk"],
            bodyWithSource: """
            Zwischen 1645 und 1715 erlebte Europa das eiskalte **Maunder-Minimum**. Alpenfichten wuchsen extrem langsam und bildeten ungewöhnlich dichte, feine Jahresringe.

            Antonio Stradivari schnitzte seine berühmtesten Geigen aus genau diesem *klimaverdichteten Holz* – das Geheimnis war der Winter im Holz.

            Quelle: Henri Grissino-Mayer & Lloyd Burckle, Dendrochronologia (2003)
            """,
            deepDiveWithSource: """
            In den kältesten Jahrzehnten der Kleinen Eiszeit zwangen kurze Sommer die Fichten der italienischen Alpen zu extrem gleichmäßigen Zellen. Diese zufällige Akustik-Ingenieurskunst leitete Schallwellen schneller und verlustärmer durch die Geigendecke.

            2008 zeigte der Schweizer Forscher Francis Schwarze, dass spezielle Holzpilze diese gleichmäßige Zelldichte nachbilden können. In Blindtests hielten Zuhörer das behandelte Instrument für eine echte Stradivari von 1711.

            Quelle: Francis W. M. R. Schwarze et al., New Phytologist (2008)
            """
        ),
        GuestStaticPost(
            id: "kurosawa-ink-rain",
            categoryId: "film",
            title: "Warum Kurosawa schwarze Tinte in den Regen goss",
            tags: ["Film", "Handwerk", "Regie"],
            bodyWithSource: """
            Bei den Dreharbeiten zu *Rashomon* (**1950**) merkte Akira Kurosawa, dass echter Regen auf Schwarz-Weiß-Film vor dem hellen Himmel völlig unsichtbar blieb.

            Seine Lösung war pure visuelle Alchemie: Er ließ **schwarze Tusche** in die Löschpumpen mischen, sodass aus unsichtbarem Nieselregen scharfe Striche auf der Leinwand wurden.

            Quelle: Donald Richie, The Films of Akira Kurosawa (1965)
            """,
            deepDiveWithSource: """
            Monochromfilm erfasst Helligkeit statt Farbe – klares Wasser reflektiert schlicht das Himmelslicht und verschwindet. Kurosawa färbte nicht nur das Wasser dunkel, sondern stellte dunkle Stoffwände hinter das verfallene Rashomon-Tor, sodass jeder Tropfen wie ein Pinselstrich wirkte.

            Dieselbe Besessenheit prägte *Die sieben Samurai* (1954), wo Matsch und strömender Regen jede Samurai-Romantik hinwegspülten.

            Quelle: Akira Kurosawa, Something Like an Autobiography (1982)
            """
        ),
        GuestStaticPost(
            id: "roman-concrete",
            categoryId: "science",
            title: "Warum römischer Beton sich selbst heilt",
            tags: ["Wissenschaft", "Architektur", "Material"],
            bodyWithSource: """
            Moderner Portlandzement zerbröselt im Meerwasser oft nach wenigen Jahrzehnten, während **2.000 Jahre alte** römische Hafenmolen bis heute stehen.

            2023 bewiesen MIT-Forschende: Die weißen Einschlüsse im Römerbeton sind **heiß gemischte Branntkalk-Klasten**, die bei Wassereintritt zu frischem Kalzit kristallisieren und Risse selbst verschließen.

            Quelle: Admir Masic et al., Science Advances (2023)
            """,
            deepDiveWithSource: """
            Lange hielt man die weißen Körnchen für schlampiges Mischen. Durch hochauflösende Röntgenanalysen und antike Bauanleitungen zeigte Admir Masics Team, dass römische Baumeister Vulkanasche bewusst mit ungelöschtem Kalk bei hohen Temperaturen verarbeiteten.

            Dringt Meerwasser in einen Haarriss ein, lösen sich die kalkreichen Einschlüsse und füllen den Spalt eigenständig mit Kalzit, bevor sich der Riss ausbreiten kann.

            Quelle: Linda M. Seymour et al., Science Advances (2023)
            """
        ),
        GuestStaticPost(
            id: "1904-marathon",
            categoryId: "sports",
            title: "Der chaotischste Marathon der Olympia-Geschichte",
            tags: ["Sport", "Geschichte", "Olympia"],
            bodyWithSource: """
            Beim **Olympia-Marathon 1904** in St. Louis liefen 32 Starter über staubige Feldwege zu einem einzigen Brunnen – und ein Läufer wurde von wilden Hunden abgedrängt.

            Sieger Thomas Hicks überstand das Rennen nur dank *Strychnin (Rattengift) und Brandy*, die ihm seine Betreuer unterwegs einflößten.

            Quelle: David E. Martin & Roger W. H. Gynn, The Olympic Marathon (2000)
            """,
            deepDiveWithSource: """
            Das Rennen startete um 15 Uhr bei 32 Grad Hitze, während Begleitfahrzeuge dichte Staubwolken aufwirbelten. Der Kubaner Félix Carvajal schnitt sich seine Straßenhose über den Knien ab und aß unterwegs verdorbene Äpfel, die ihn zu einer unfreiwilligen Pause zwangen.

            Fred Lorz fuhr elf Meilen per Auto und joggte zum Scherz als Erster ins Ziel – bevor der Schwindel aufflog und der halluzinierende Hicks die Medaille erhielt.

            Quelle: Charles J. P. Lucas, The Olympic Games 1904 (1905)
            """
        ),
        GuestStaticPost(
            id: "tokyo-station-melodies",
            categoryId: "travel",
            title: "Warum Tokios Bahnhöfe 7-Sekunden-Melodien spielen",
            tags: ["Design", "Reisen", "Musik"],
            bodyWithSource: """
            Auf Tokios Yamanote-Linie erklingt statt schriller Klingeln an jedem Bahnsteig eine eigene **7-Sekunden-Melodie** (*Hassha Merodī*).

            Klangpsychologen komponierten für jede Station ein Motiv, damit Pendler ihren Halt am Klang erkennen und *messbar seltener* hektisch zu Türen sprinten.

            Quelle: Minoru Mukaiya, Ongakukan Archives (2012)
            """,
            deepDiveWithSource: """
            Vor 1989 trieben schrille Alarmglocken den Stresspegel und riskante Spurtmanöver in die Höhe. JR East ersetzte die Signale gemeinsam mit Musiker Minoru Mukaiya durch sanfte Dur-Melodien.

            Viele Stationen greifen lokale Geschichte auf – in Takadanobaba ertönt die Titelmelodie von *Astro Boy*, wo Zeichner Osamu Tezuka arbeitete, und verwandelt den Alltag in entspannte Orientierung.

            Quelle: East Japan Railway Culture Foundation Archives (2010)
            """
        ),
        GuestStaticPost(
            id: "xray-jazz",
            categoryId: "art",
            title: "Als Jazz auf alten Röntgenbildern gepresst wurde",
            tags: ["Musik", "Geschichte", "Kultur"],
            bodyWithSource: """
            Als Jazz im **Leningrad der 1950er** verboten war, suchten Untergrund-Tontechniker nach billigem Material für illegale Schallplatten.

            Sie holten **ausrangierte Röntgenbilder** aus Klinikmüll, schnitten sie mit Nagelscheren rund, brannten mit einer Zigarette ein Mittelloch hinein und ritzten Miles Davis direkt auf Rippenbögen.

            Quelle: Stephen Coates, X-Ray Audio (2015)
            """,
            deepDiveWithSource: """
            Die sogenannten „Knochenplatten“ (*Roentgenizdat*) fassten einen Drei-Minuten-Track bei 78 Umdrehungen und hielten etwa zwanzig Abspielvorgänge aus. Mit selbstgebauten Schneidemaschinen aus alten Grammophonen verkauften Bootlegger die bläulichen Folien für einen Rubel.

            Trotz Razzien kursierten Millionen dieser geisterhaften Platten – ein Beweis, wie kreativ Neugier Zensur umgeht.

            Quelle: Anya von Bremzen, Mastering the Art of Soviet Cooking (2013)
            """
        ),
        GuestStaticPost(
            id: "immortal-jellyfish",
            categoryId: "nature",
            title: "Die winzige Qualle, die ihre Lebensuhr zurückdreht",
            tags: ["Natur", "Wissenschaft", "Biologie"],
            bodyWithSource: """
            Fast jedes Tier altert nur in eine Richtung. Die kaum fingergroße Qualle *Turritopsis dohrnii* bricht diese Regel per **Transdifferenzierung**.

            Bei Verletzung oder Hunger sinkt die erwachsene Qualle zu Boden, zieht ihre Tentakel ein und verwandelt sich zurück in einen **jungen Polypen**, der neue Klone bildet.

            Quelle: Stefano Piraino et al., Biological Bulletin (1996)
            """,
            deepDiveWithSource: """
            In den 1980er-Jahren beschrieben Meeresbiologen erstmals, dass die Qualle nicht bloß das Altern anhält: Ihre spezialisierten Nerven- und Muskelzellen programmieren sich tatsächlich wieder zu stammzellähnlichen Polypenzellen um.

            Eine Genomanalyse von 2022 zeigte doppelt ausgeprägte Gene für DNA-Reparatur und Telomer-Schutz – ein spannendes Modell für Zellerneuerung ohne Tumorwachstum.

            Quelle: Maria Pascual-Torner et al., PNAS (2022)
            """
        )
    ]

    // MARK: - French (8 Stories)

    private static let frenchPosts: [GuestStaticPost] = [
        GuestStaticPost(
            id: "oxford-aztec",
            categoryId: "history",
            title: "L'université d'Oxford est plus ancienne que l'Empire aztèque",
            tags: ["Histoire", "Chronologie", "Culture"],
            bodyWithSource: """
            On enseignait déjà à Oxford vers **1096**, plus de *deux siècles avant* la fondation de Tenochtitlan en 1325.

            Lorsque l'Empire aztèque se forma en **1428**, Oxford diplômait des érudits depuis plus de 300 ans. Nos repères chronologiques se chevauchent bien plus qu'on ne l'imagine.

            Source : L. W. B. Brockliss, The University of Oxford: A History (2016)
            """,
            deepDiveWithSource: """
            En 1428, alors que la Triple Alliance aztèque unifiait la vallée de Mexico, la plus vieille bibliothèque d'Oxford s'agrandissait déjà — et le Machu Picchu ne serait bâti que vingt ans plus tard.

            Notre mémoire cloisonne l'Europe médiévale et la Mésoamérique, alors qu'elles ont coexisté pendant des générations. Plus tôt encore, Al Quaraouiyine (859) et Bologne (1088) formaient déjà des générations d'étudiants.

            Source : Michael E. Smith, The Aztecs (2012)
            """
        ),
        GuestStaticPost(
            id: "stradivarius-ice-age",
            categoryId: "music",
            title: "Comment un petit âge glaciaire a forgé le son Stradivarius",
            tags: ["Musique", "Climat", "Artisanat"],
            bodyWithSource: """
            Entre 1645 et 1715, l'Europe connut le glacial **minimum de Maunder**. Les épicéas alpins poussèrent si lentement que leurs cernes devinrent extraordinairement denses.

            Antonio Stradivari sculpta ses violons d'or dans ce *bois comprimé par le climat* : le secret résidait dans l'hiver figé dans la fibre.

            Source : Henri Grissino-Mayer & Lloyd Burckle, Dendrochronologia (2003)
            """,
            deepDiveWithSource: """
            Durant les décennies les plus froides du petit âge glaciaire, des étés courts imposèrent aux épicéas alpins une structure cellulaire d'une homogénéité rare, accélérant la propagation acoustique dans la table d'harmonie.

            En 2008, le chercheur suisse Francis Schwarze utilisa des champignons spécifiques pour reproduire cette densité cellulaire. Lors d'écoutes à l'aveugle, les experts confondirent l'instrument traité avec un véritable Stradivarius de 1711.

            Source : Francis W. M. R. Schwarze et al., New Phytologist (2008)
            """
        ),
        GuestStaticPost(
            id: "kurosawa-ink-rain",
            categoryId: "film",
            title: "Pourquoi Kurosawa versa de l'encre noire dans la pluie",
            tags: ["Cinéma", "Mise en scène", "Artisanat"],
            bodyWithSource: """
            En tournant *Rashomon* (**1950**), Akira Kurosawa constata que la vraie pluie disparaissait complètement devant le ciel clair sur pellicule noir et blanc.

            Son remède fut pure alchimie visuelle : il fit mélanger de l'**encre de Chine noire** à l'eau des lances à incendie pour transformer une bruine invisible en traits tranchants à l'écran.

            Source : Donald Richie, The Films of Akira Kurosawa (1965)
            """,
            deepDiveWithSource: """
            Le film monochrome capte la luminance et non la couleur ; l'eau claire reflète simplement le ciel et s'efface. Kurosawa ne se contenta pas de teinter l'eau : il tendit des toiles sombres derrière la porte en ruine de Rashomon pour que chaque goutte tranche comme un coup de pinceau.

            Cette obsession climatique culmine dans *Les Sept Samouraïs* (1954), où la boue et le déluge balayent toute romance chevaleresque.

            Source : Akira Kurosawa, Comme une autobiographie (1982)
            """
        ),
        GuestStaticPost(
            id: "roman-concrete",
            categoryId: "science",
            title: "Pourquoi le béton romain répare ses propres fissures",
            tags: ["Sciences", "Architecture", "Matériaux"],
            bodyWithSource: """
            Le ciment moderne s'effrite en quelques décennies dans l'eau de mer, tandis que les ports romains vieux de **2 000 ans** tiennent toujours.

            En 2023, le MIT a révélé que les grains blancs du béton romain sont des **clastes de chaux vive mélangés à chaud** qui réagissent avec l'eau pour sceller automatiquement les fissures.

            Source : Admir Masic et al., Science Advances (2023)
            """,
            deepDiveWithSource: """
            Pendant longtemps, les ingénieurs ont pris ces éclats blancs pour un brassage négligé. Grâce à l'imagerie aux rayons X et aux traités antiques, l'équipe d'Admir Masic a prouvé que les Romains mélangeaient cendres volcaniques et chaux vive à haute température.

            Dès que l'eau de mer s'infiltre dans une microfissure, la chaux se dissout et recristallise en calcite neuve, colmatant la brèche avant toute rupture.

            Source : Linda M. Seymour et al., Science Advances (2023)
            """
        ),
        GuestStaticPost(
            id: "1904-marathon",
            categoryId: "sports",
            title: "Le marathon le plus chaotique de l'histoire olympique",
            tags: ["Sport", "Histoire", "Jeux olympiques"],
            bodyWithSource: """
            Le **marathon olympique de 1904** à Saint-Louis réunit 32 coureurs sur des chemins poussiéreux avec un seul puits d'eau et un athlète chassé hors piste par des chiens sauvages.

            Le vainqueur Thomas Hicks tint grâce à un mélange de *strychnine (mort-aux-rats) et de cognac* donné en course, avant d'être porté sur la ligne.

            Source : David E. Martin & Roger W. H. Gynn, The Olympic Marathon (2000)
            """,
            deepDiveWithSource: """
            Lancé à 15 h sous 32 °C, le peloton étouffait dans la poussière des voitures officielles. Le Cubain Félix Carvajal coupa son pantalon de ville aux genoux et s'arrêta manger des pommes avariées qui le clouèrent de crampes.

            Quant à Fred Lorz, il parcourut 17 km en voiture avant de franchir la ligne pour plaisanter — la supercherie fut vite découverte et l'or revint à un Hicks en plein délire.

            Source : Charles J. P. Lucas, The Olympic Games 1904 (1905)
            """
        ),
        GuestStaticPost(
            id: "tokyo-station-melodies",
            categoryId: "travel",
            title: "Pourquoi les gares de Tokyo jouent des mélodies de 7 secondes",
            tags: ["Design", "Voyage", "Musique"],
            bodyWithSource: """
            Sur la ligne Yamanote à Tokyo, chaque quai remplace la sonnerie stridente par une **mélodie originale de 7 secondes** (*hassha merodī*).

            Les designers sonores ont composé un thème distinct par gare afin que les voyageurs reconnaissent leur arrêt à l'oreille et ressentent *nettement moins d'urgence* à courir vers les portes.

            Source : Minoru Mukaiya, Archives Ongakukan (2012)
            """,
            deepDiveWithSource: """
            Avant 1989, des sonneries électriques perçantes augmentaient le stress des usagers et provoquaient des courses dangereuses sur les quais. JR East fit appel à des psycho-acousticiens et au musicien Minoru Mukaiya pour remplacer l'alerte par de courtes phrases apaisantes.

            Chaque quartier possède son clin d'œil sonore, transformant la foule matinale en un repérage musical fluide et apaisé.

            Source : Archives East Japan Railway Culture Foundation (2010)
            """
        ),
        GuestStaticPost(
            id: "xray-jazz",
            categoryId: "art",
            title: "Quand le jazz était gravé sur des radios médicales",
            tags: ["Musique", "Histoire", "Culture"],
            bodyWithSource: """
            Lorsque le jazz fut interdit dans le **Leningrad des années 1950**, les ingénieurs clandestins cherchèrent un support bon marché pour presser des disques pirates.

            Ils récupéraient des **radiographies d'hôpital jetées**, les découpaient en cercle aux ciseaux, perçaient le centre à la cigarette et gravaient Miles Davis sur des cages thoraciques.

            Source : Stephen Coates, X-Ray Audio (2015)
            """,
            deepDiveWithSource: """
            Surnommés *roentgenizdat* (« musique sur os »), ces disques souples contenaient un titre de trois minutes à 78 tours et s'usaient après une vingtaine d'écoutes. Les contrebandiers fabriquaient leurs propres graveurs et vendaient ces feuilles bleutées un rouble dans les ruelles.

            Malgré les arrestations, des millions de disques radiographiques circulèrent en URSS, prouvant que la curiosité contourne toujours la censure avec les moyens du bord.

            Source : Anya von Bremzen, Mastering the Art of Soviet Cooking (2013)
            """
        ),
        GuestStaticPost(
            id: "immortal-jellyfish",
            categoryId: "nature",
            title: "La minuscule méduse qui remonte sa propre horloge",
            tags: ["Nature", "Sciences", "Biologie"],
            bodyWithSource: """
            Presque tous les animaux vieillissent dans un seul sens. *Turritopsis dohrnii*, pas plus grande qu'un ongle, défie la règle par **transdifférenciation**.

            Blessée ou affamée, la méduse adulte coule au fond, résorbe ses tentacules et redevient un **jeune polype** prêt à se cloner à nouveau.

            Source : Stefano Piraino et al., Biological Bulletin (1996)
            """,
            deepDiveWithSource: """
            Observée dans les années 1980, cette méduse ne suspend pas simplement le temps : ses cellules nerveuses et musculaires spécialisées réécrivent leur identité pour redevenir des cellules souches de polype.

            Un séquençage génomique de 2022 a révélé chez elle des copies supplémentaires de gènes dédiés à la réparation de l'ADN et à la protection des télomères.

            Source : Maria Pascual-Torner et al., PNAS (2022)
            """
        )
    ]

    // MARK: - Spanish (8 Stories)

    private static let spanishPosts: [GuestStaticPost] = [
        GuestStaticPost(
            id: "oxford-aztec",
            categoryId: "history",
            title: "La Universidad de Oxford es más antigua que el Imperio azteca",
            tags: ["Historia", "Cronología", "Cultura"],
            bodyWithSource: """
            En Oxford ya se impartían clases hacia **1096**, más de *dos siglos antes* de que los aztecas fundaran Tenochtitlán en 1325.

            Cuando nació el Imperio azteca en **1428**, Oxford llevaba más de 300 años graduando estudiantes. Las líneas de tiempo se cruzan de formas mucho más cercanas de lo que parece.

            Fuente: L. W. B. Brockliss, The University of Oxford: A History (2016)
            """,
            deepDiveWithSource: """
            Cuando la Triple Alianza azteca unió el Valle de México en 1428, la biblioteca más antigua de Oxford ya se estaba ampliando y Machu Picchu tardaría aún veinte años en construirse.

            Solemos imaginar la Europa medieval y Mesoamérica como épocas aisladas, cuando en realidad convivieron durante generaciones. Incluso antes, al-Qarawiyyin (859) y Bolonia (1088) ya formaban eruditos.

            Fuente: Michael E. Smith, The Aztecs (2012)
            """
        ),
        GuestStaticPost(
            id: "stradivarius-ice-age",
            categoryId: "music",
            title: "Cómo una Pequeña Edad de Hielo creó el sonido Stradivarius",
            tags: ["Música", "Clima", "Artesanía"],
            bodyWithSource: """
            Entre 1645 y 1715 Europa atravesó el frío **Mínimo de Maunder**. Los abetos alpinos crecieron tan lento que sus anillos se volvieron ultradensos.

            Antonio Stradivari talló sus mejores violines en aquella *madera comprimida por el clima*: el secreto no era un barniz, sino el invierno atrapado en la veta.

            Fuente: Henri Grissino-Mayer & Lloyd Burckle, Dendrochronologia (2003)
            """,
            deepDiveWithSource: """
            Durante las décadas más gélidas, los veranos breves obligaron a los abetos alpinos a formar células extraordinariamente uniformes que aceleraban la propagación del sonido con mínima pérdida acústica.

            En 2008, el investigador suizo Francis Schwarze reprodujo esa densidad celular tratando madera con hongos específicos. En pruebas a ciegas, el público confundió ese violín con un Stradivarius auténtico de 1711.

            Fuente: Francis W. M. R. Schwarze et al., New Phytologist (2008)
            """
        ),
        GuestStaticPost(
            id: "kurosawa-ink-rain",
            categoryId: "film",
            title: "Por qué Kurosawa mezcló tinta negra en la lluvia",
            tags: ["Cine", "Dirección", "Artesanía"],
            bodyWithSource: """
            Mientras rodaba *Rashomon* en **1950**, Akira Kurosawa notó que la lluvia real desaparecía por completo sobre el cielo claro en película en blanco y negro.

            Su solución fue pura alquimia visual: ordenó mezclar **tinta caligráfica negra** con el agua de los camiones de bomberos para convertir la llovizna en trazos nítidos.

            Fuente: Donald Richie, The Films of Akira Kurosawa (1965)
            """,
            deepDiveWithSource: """
            La película monocroma capta luminancia y no color, de modo que las gotas transparentes reflejan el cielo y se desvanecen. Kurosawa no solo tiñó el agua: colocó fondos oscuros y contraluces tras el pórtico en ruinas para que cada gota luciera como pincelada.

            Esa obsesión culminó en *Los siete samuráis* (1954), donde el barro y el aguacero borraron todo romanticismo épico.

            Fuente: Akira Kurosawa, Autobiografía (1982)
            """
        ),
        GuestStaticPost(
            id: "roman-concrete",
            categoryId: "science",
            title: "Por qué el hormigón romano repara sus propias grietas",
            tags: ["Ciencia", "Arquitectura", "Materiales"],
            bodyWithSource: """
            El cemento Portland moderno se deshace en el mar en pocas décadas, pero los puertos romanos de hace **2.000 años** siguen intactos.

            En 2023, el MIT descubrió que las motas blancas del hormigón romano son **clastos de cal viva mezclados en caliente** que reaccionan con el agua para cristalizar calcita y sellar grietas automáticamente.

            Fuente: Admir Masic et al., Science Advances (2023)
            """,
            deepDiveWithSource: """
            Durante décadas se pensó que los obreros romanos simplemente mezclaban mal el mortero. Mediante rayos X de alta resolución y tratados antiguos, el equipo de Admir Masic demostró que combinaban ceniza volcánica y cal viva a temperaturas altísimas.

            Cuando entra agua de mar en una fisura, esos granos ricos en calcio se disuelven y rellenan el hueco antes de que el muro se parta.

            Fuente: Linda M. Seymour et al., Science Advances (2023)
            """
        ),
        GuestStaticPost(
            id: "1904-marathon",
            categoryId: "sports",
            title: "El maratón más caótico en la historia olímpica",
            tags: ["Deportes", "Historia", "Olimpiadas"],
            bodyWithSource: """
            El **maratón olímpico de St. Louis 1904** tuvo 32 corredores sobre tierra polvorienta, un solo pozo de agua en el kilómetro 19 y un atleta perseguido por perros salvajes.

            El ganador Thomas Hicks sobrevivió gracias a *estricnina (veneno para ratas) y brandy* que su equipo le dio en plena carrera.

            Fuente: David E. Martin & Roger W. H. Gynn, The Olympic Marathon (2000)
            """,
            deepDiveWithSource: """
            La prueba arrancó a las 3 de la tarde con 32 °C y coches levantando nubes de polvo delante de los atletas. El cubano Félix Carvajal corrió con pantalones de calle cortados y sufrió calambres tras comer manzanas en mal estado.

            Fred Lorz recorrió 17 kilómetros en automóvil y cruzó primero la meta en broma, antes de que la organización descalificara el truco y premiara a un Hicks alucinando.

            Fuente: Charles J. P. Lucas, The Olympic Games 1904 (1905)
            """
        ),
        GuestStaticPost(
            id: "tokyo-station-melodies",
            categoryId: "travel",
            title: "Por qué los andenes de Tokio suenan con melodías de 7 segundos",
            tags: ["Diseño", "Viajes", "Música"],
            bodyWithSource: """
            En la línea Yamanote de Tokio, en lugar de timbres estridentes, cada andén reproduce una **melodía única de 7 segundos** (*hassha merodī*).

            Diseñadores sonoros crearon motivos distintos por estación para que los pasajeros reconozcan su parada de oído y sientan *menos ansiedad* por correr hacia las puertas.

            Fuente: Minoru Mukaiya, Ongakukan Archives (2012)
            """,
            deepDiveWithSource: """
            Antes de 1989, las campanas eléctricas disparaban el estrés y provocaban carreras peligrosas en hora punta. JR East colaboró con psicólogos acústicos y el músico Minoru Mukaiya para sustituir las alarmas por breves frases en tono mayor.

            Cada estación evoca su barrio: en Takadanobaba suena *Astro Boy* en honor a Osamu Tezuka, convirtiendo el trayecto diario en orientación serena.

            Fuente: East Japan Railway Culture Foundation Archives (2010)
            """
        ),
        GuestStaticPost(
            id: "xray-jazz",
            categoryId: "art",
            title: "Cuando grababan discos de jazz en radiografías de hospital",
            tags: ["Música", "Historia", "Cultura"],
            bodyWithSource: """
            Al prohibirse el jazz en el **Leningrado de los años 50**, ingenieros clandestinos buscaron un material barato para prensar música prohibida.

            Recogieron **radiografías descartadas** de hospitales, las recortaron en círculo con tijeras de manicura, perforaron el centro con un cigarrillo y grabaron a Miles Davis sobre costillas y cráneos.

            Fuente: Stephen Coates, X-Ray Audio (2015)
            """,
            deepDiveWithSource: """
            Llamados *roentgenizdat* («música en huesos»), estos discos flexibles guardaban una canción de tres minutos a 78 rpm y duraban unas veinte reproducciones. Los contrabandistas armaron tornos caseros con piezas de gramófono y vendían cada lámina azul por un rublo.

            Pese a las redadas, millones de placas fantasma recorrieron la URSS demostrando cómo el ingenio sortea cualquier censura.

            Fuente: Anya von Bremzen, Mastering the Art of Soviet Cooking (2013)
            """
        ),
        GuestStaticPost(
            id: "immortal-jellyfish",
            categoryId: "nature",
            title: "La diminuta medusa que reinicia su reloj biológico",
            tags: ["Naturaleza", "Ciencia", "Biología"],
            bodyWithSource: """
            Casi todos los animales envejecen en una sola dirección. *Turritopsis dohrnii*, del tamaño de una uña, rompe esa regla mediante **transdiferenciación**.

            Cuando sufre daño o hambre, la medusa adulta cae al fondo, absorbe sus tentáculos y vuelve a transformarse en un **pólipo juvenil** listo para clonarse.

            Fuente: Stefano Piraino et al., Biological Bulletin (1996)
            """,
            deepDiveWithSource: """
            Documentada en los años 80, esta medusa no solo frena el envejecimiento: sus células nerviosas y musculares especializadas borran su identidad y vuelven a ser tejido juvenil tipo célula madre.

            La secuenciación genómica de 2022 reveló copias extra de genes reparadores de ADN y protectores de telómeros frente a especies mortales emparentadas.

            Fuente: Maria Pascual-Torner et al., PNAS (2022)
            """
        )
    ]

    // MARK: - Korean (8 Stories)

    private static let koreanPosts: [GuestStaticPost] = [
        GuestStaticPost(
            id: "oxford-aztec",
            categoryId: "history",
            title: "옥스퍼드 대학교는 아즈텍 제국보다 오래되었습니다",
            tags: ["역사", "연대기", "교양"],
            bodyWithSource: """
            옥스퍼드에서는 이미 **1096년** 무렵 강의가 열렸고, 1249년에는 공식 칼리지가 세워졌습니다—아즈텍이 1325년에 테노치티틀란을 세우기 *두 세기 이상 앞선* 시기입니다.

            **1428년** 아즈텍 제국이 출범할 때 옥스퍼드는 이미 300년 넘게 학자를 배출하고 있었습니다.

            출처: L. W. B. Brockliss, The University of Oxford: A History (2016)
            """,
            deepDiveWithSource: """
            1428년 아즈텍 삼국 동맹이 멕시코 계곡을 통합할 무렵 옥스퍼드의 가장 오래된 도서관은 이미 확장 중이었고, 마추픽추는 그보다 20년 뒤에야 지어졌습니다.

            우리는 중세 유럽과 메소아메리카를 완전히 떨어진 시대처럼 떠올리지만 실제로는 여러 세대에 걸쳐 공존했습니다. 페스의 알카라위인 대학(859)과 볼로냐 대학(1088)은 그보다 더 먼저 문을 열었습니다.

            출처: Michael E. Smith, The Aztecs (2012)
            """
        ),
        GuestStaticPost(
            id: "stradivarius-ice-age",
            categoryId: "music",
            title: "소빙기가 빚어낸 스트라디바리우스의 울림",
            tags: ["음악", "기후", "공예"],
            bodyWithSource: """
            1645년부터 1715년까지 유럽은 혹독한 **마운더 극소기**를 겪었습니다. 알프스의 가문비나무가 아주 천천히 자라며 나이테가 촘촘하고 치밀하게 응축되었죠.

            스트라디바리는 바로 그 *기후가 압축한 목재*로 황금기 바이올린을 깎았습니다. 전설의 비결은 니스가 아니라 나뭇결에 얼어붙은 겨울이었습니다.

            출처: Henri Grissino-Mayer & Lloyd Burckle, Dendrochronologia (2003)
            """,
            deepDiveWithSource: """
            소빙기의 가장 추웠던 수십 년 동안 짧은 여름은 알프스 가문비나무 세포를 놀라울 만큼 균일하고 밀도 높게 만들었습니다. 이 우연한 음향 공학이 앞판의 진동 전달력을 높여 주었습니다.

            2008년 스위스 연구자 프란시스 슈바르체는 특정 균류로 목재의 세포 밀도를 조절해 당시의 음향 특성을 재현했고, 블라인드 테스트에서 연주자들조차 1711년산 진품과 구별하지 못했습니다.

            출처: Francis W. M. R. Schwarze et al., New Phytologist (2008)
            """
        ),
        GuestStaticPost(
            id: "kurosawa-ink-rain",
            categoryId: "film",
            title: "구로사와 아키라가 빗물에 검은 먹물을 섞은 이유",
            tags: ["영화", "연출", "장인정신"],
            bodyWithSource: """
            **1950년** 《라쇼몽》을 촬영하던 구로사와 아키라는 흑백 필름 위에서 진짜 빗줄기가 밝은 하늘에 묻혀 거의 보이지 않는다는 사실을 알게 되었습니다.

            그의 해법은 순수한 시각적 연금술이었습니다. 소방 펌프로 뿌리는 물에 **검은 먹물**을 타서 보이지 않던 가랑비를 화면 위 날카로운 선으로 바꿔 놓았습니다.

            출처: Donald Richie, The Films of Akira Kurosawa (1965)
            """,
            deepDiveWithSource: """
            흑백 필름은 색상이 아니라 밝기를 기록하기 때문에 투명한 물방울은 하늘빛을 반사해 배경으로 사라집니다. 구로사와는 물을 검게 물들였을 뿐 아니라 폐허가 된 라쇼몽 성문 뒤에 어두운 배경막과 역광을 배치해 빗방울 하나하나를 붓질처럼 살려냈습니다.

            날씨를 감정의 장치로 삼은 이 집념은 진흙과 폭우가 사무라이의 낭만을 씻어 내린 《7인의 사무라이》(1954)에서 절정에 달했습니다.

            출처: Akira Kurosawa, Something Like an Autobiography (1982)
            """
        ),
        GuestStaticPost(
            id: "roman-concrete",
            categoryId: "science",
            title: "스스로 균열을 메우는 고대 로마 콘크리트의 비밀",
            tags: ["과학", "건축", "재료"],
            bodyWithSource: """
            현대 포틀랜드 시멘트는 바닷물에서 수십 년 만에 부식되지만, **2,000년 전** 로마 항구들은 지금도 굳건합니다.

            2023년 MIT 연구진은 콘크리트 속 흰 알갱이가 배합 실수가 아니라, 스며든 물과 반응해 새 방해석을 결정화하며 균열을 스스로 메우는 **고온 혼합 생석회**임을 밝혀냈습니다.

            출처: Admir Masic et al., Science Advances (2023)
            """,
            deepDiveWithSource: """
            오랫동안 공학자들은 로마 장인들이 모르타르를 덜 저어서 흰 덩어리가 남았다고 여겼습니다. 그러나 고해상도 X선 분석과 고대 건축 문헌을 대조한 연구는 화산재와 생석회를 고열에서 의도적으로 섞었음을 입증했습니다.

            바닷물이 미세한 틈으로 스며들면 칼슘 성분이 녹아 나와 빈틈을 다시 결정으로 채우며 구조가 갈라지는 것을 막아 줍니다.

            출처: Linda M. Seymour et al., Science Advances (2023)
            """
        ),
        GuestStaticPost(
            id: "1904-marathon",
            categoryId: "sports",
            title: "올림픽 역사상 가장 기상천외했던 1904년 마라톤",
            tags: ["스포츠", "역사", "올림픽"],
            bodyWithSource: """
            **1904년 세인트루이스 올림픽 마라톤**은 비포장 흙길에 급수대가 19km 지점 단 한 곳뿐이었고, 야생 들개에 쫓겨 코스를 벗어난 주자까지 있었습니다.

            우승자 토머스 힉스는 트레이너가 도중에 건넨 *쥐약(스트리크닌)과 브랜디*에 의지한 채 부축을 받으며 결승선을 넘었습니다.

            출처: David E. Martin & Roger W. H. Gynn, The Olympic Marathon (2000)
            """,
            deepDiveWithSource: """
            섭씨 32도의 오후 3시에 출발한 선수들은 선두 차량이 일으킨 먼지 구름에 숨이 막혔습니다. 쿠바의 우편배달부 펠릭스 카르바할은 평상복 바지를 무릎 위로 잘라 입고 달리다 상한 사과를 먹고 복통으로 길가에 쓰러졌습니다.

            프레드 로즈는 17km를 자동차로 이동한 뒤 장난삼아 1위로 골인했다가 실격당했고, 환각 상태의 힉스가 결국 금메달을 받았습니다.

            출처: Charles J. P. Lucas, The Olympic Games 1904 (1905)
            """
        ),
        GuestStaticPost(
            id: "tokyo-station-melodies",
            categoryId: "travel",
            title: "도쿄 지하철 승강장이 7초 멜로디를 트는 이유",
            tags: ["디자인", "여행", "음악"],
            bodyWithSource: """
            도쿄 야마노테선 승강장에서는 날카로운 부저 대신 역마다 고유한 **7초 멜로디**(*핫샤 멜로디*)가 흘러나옵니다.

            음향 디자이너들은 졸린 승객이 소리만으로 정차역을 구분하고, 닫히는 문으로 *뛰어드는 조급함을 줄이도록* 역별 맞춤 선율을 작곡했습니다.

            출처: Minoru Mukaiya, Ongakukan Sound Archives (2012)
            """,
            deepDiveWithSource: """
            1989년 이전 일본 철도역의 요란한 전자벨은 승객의 긴장감을 높여 위험한 막판 질주를 부추겼습니다. JR 동일본은 음향 심리학자 및 음악가 무카이야 미노루와 협업해 경보음을 부드러운 장조 선율로 바꿨습니다.

            다카다노바바역에는 데즈카 오사무를 기리는 《철완 아톰》 테마가 흐르는 등 지역 문화를 담은 소리가 도시의 차분한 길잡이가 되었습니다.

            출처: East Japan Railway Culture Foundation Archives (2010)
            """
        ),
        GuestStaticPost(
            id: "xray-jazz",
            categoryId: "art",
            title: "병원 엑스레이 필름에 새겨진 비밀 재즈 음반",
            tags: ["음악", "역사", "문화"],
            bodyWithSource: """
            **1950년대 레닌그라드**에서 재즈와 서구 록이 금지되자, 지하 음향 기술자들은 값싼 음반 재료를 찾아 나섰습니다.

            그들은 병원 쓰레기장에서 **버려진 엑스레이 필름**을 모아 손톱가위로 둥글게 오리고 담뱃불로 구멍을 뚫어 갈비뼈 사진 위에 마일스 데이비스를 새겼습니다.

            출처: Stephen Coates, X-Ray Audio (2015)
            """,
            deepDiveWithSource: """
            ‘뼈 음악(뢴트게니즈다트)’이라 불린 이 얇은 필름 음반은 78rpm으로 3분짜리 한 곡이 담겼고 약 20번 재생하면 닳아 없어졌습니다. 밀매업자들은 고장 난 축음기 부품으로 커팅 기계를 직접 만들어 푸른 반투명 음반을 뒷골목에서 1루블에 팔았습니다.

            단속과 투옥에도 수백만 장의 엑스레이 음반이 소련 전역으로 퍼지며 호기심이 어떻게 검열을 비켜가는지 보여주었습니다.

            출처: Anya von Bremzen, Mastering the Art of Soviet Cooking (2013)
            """
        ),
        GuestStaticPost(
            id: "immortal-jellyfish",
            categoryId: "nature",
            title: "생명의 시계를 어린 시절로 되돌리는 작은 해파리",
            tags: ["자연", "과학", "생물학"],
            bodyWithSource: """
            대부분의 동물은 한 방향으로만 늙어갑니다. 새끼손톱보다 작은 **홍해파리**(*Turritopsis dohrnii*)는 **교차분화**로 이 법칙을 거스릅니다.

            다치거나 굶주리면 성체 해파리는 바다 바닥으로 가라앉아 촉수를 흡수하고, 다시 스스로를 복제하는 **어린 폴립**으로 되돌아갑니다.

            출처: Stefano Piraino et al., Biological Bulletin (1996)
            """,
            deepDiveWithSource: """
            1980년대 해양생물학자들이 처음 보고한 이 현상은 단순한 노화 정지가 아닙니다. 이미 분화한 성체의 신경·근육 세포가 정체성을 지우고 줄기세포 같은 폴립 조직으로 재편성되는 과정입니다.

            2022년 유전체 분석 결과, 이 해파리는 일반 해파리보다 DNA 복구와 텔로미어 보호 유전자를 여분으로 보유해 암 변이 없는 세포 회춘 연구의 단서를 제공하고 있습니다.

            출처: Maria Pascual-Torner et al., PNAS (2022)
            """
        )
    ]
}
