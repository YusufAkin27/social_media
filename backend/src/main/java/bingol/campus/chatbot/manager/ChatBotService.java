package bingol.campus.chatbot.manager;


import bingol.campus.chatbot.entity.News;
import bingol.campus.chatbot.entity.FoodMenu;
import bingol.campus.student.business.concretes.StudentManager;
import bingol.campus.student.entity.Student;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import javax.annotation.PostConstruct;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
public class ChatBotService {

    private final StudentManager studentManager;
    private final YemekMenusuService yemekMenusuService;
    private final HavaDurumuService havaDurumuService;
    private final NewsScraper newsScraper;
    private final ChatStateService chatStateService;

    private Map<String, List<String>> conversationResponses;
    private Map<String, String> staticResponses;
    private List<String> fallbackResponses;
    private Random random = new Random();

    @PostConstruct
    public void init() {
        staticResponses = new HashMap<>();
        conversationResponses = new HashMap<>();
        fallbackResponses = new ArrayList<>();

        initializeBasicResponses();
        initializeConversationalResponses();
        initializeFallbackResponses();
    }

    private void initializeBasicResponses() {
        // Selamlaşmalar
        addStaticResponse(new String[]{"merhaba", "selam", "selamun aleyküm", "günaydın", "iyi akşamlar"},
                "Merhaba! Size nasıl yardımcı olabilirim?");

// Veda cümleleri
        addStaticResponse(new String[]{"hoşçakal", "görüşürüz", "bay bay", "bye", "güle güle"},
                "Görüşmek üzere! Yardımcı olabileceğim başka bir şey olursa her zaman buradayım.");

// Adını sorma
        addStaticResponse(new String[]{"adın ne", "ismin ne", "sen kimsin", "kimsin", "ne diyeyim sana"},
                "Benim adım Nova, sizin dijital asistanınızım! Size nasıl yardımcı olabilirim?");

// Saat sorma
        addStaticResponse(new String[]{"saat kaç", "saat şimdi kaç", "kaç saat", "saati söyler misin"},
                "Şu anda saat: %s");

// Gün sorma
        addStaticResponse(new String[]{"bugün günlerden ne", "bugün hangi gün", "hangi gündeyiz"},
                "Bugün " + LocalDate.now().format(DateTimeFormatter.ofPattern("dd MMMM yyyy EEEE")) + ".");

// Teşekkürler
        addStaticResponse(new String[]{"teşekkür", "sağol", "teşekkürler", "teşekkür ederim"},
                "Rica ederim, her zaman buradayım! Başka bir konuda yardımcı olabilir miyim?");

// Hal hatır
        addStaticResponse(new String[]{"nasılsın", "nasılsınız", "iyisin", "iyisiniz", "keyfin nasıl", "naber", "ne haber"},
                "İyiyim, teşekkürler! Siz nasılsınız? Bugün size nasıl yardımcı olabilirim?");

// Yardım isteği
        addStaticResponse(new String[]{"yardım", "yardımcı olur musun", "ne yapabilirsin", "yardım eder misin", "bana yardım et"},
                "Size birçok konuda yardımcı olabilirim. Öğrenci bilgilerinizi gösterebilir, üniversite hakkında bilgi verebilir, günlük konuşmalar yapabilirim. Ne öğrenmek istersiniz?");
        // Şaka yap
        addStaticResponse(new String[]{"bir şaka yap", "beni güldür", "komik bir şey söylesene"},
                "Tabii! Matematik kitabı neden üzgündü? Çünkü çok problemi vardı! 😄");

        // Motive et
        addStaticResponse(new String[]{"bana motivasyon ver", "beni motive et", "motive edici bir şey söylesene"},
                "Unutma, büyük işler küçük adımlarla başlar. Bugün bir adım at, gerisi gelir! 💪");

// Kim kazandı? (espirili)
        addStaticResponse(new String[]{"galatasaray mı fenerbahçe mi", "kim daha iyi", "hangi takım şampiyon"},
                "Bu soruya tarafsız kalıyorum 😄 Ama sizin favori takımınızı destekliyorum!");

// Espirili cevap
        addStaticResponse(new String[]{"canım sıkılıyor", "sıkıldım", "çok sıkıcı"},
                "Sıkılmana gerek yok! Bir şeyler öğrenebilir, sohbet edebiliriz. Ne konuşmak istersin?");

// Boş/karmaşık girilenleri eğlenceli karşıla
        addStaticResponse(new String[]{"asdfgh", "hgfds", "......", "????", "!!!"},
                "Sanırım anlamadım 😅 Daha açık ifade edebilir misin?");

    }

    private void initializeConversationalResponses() {
        // Üniversite hakkında bilgiler
        addConversationalResponses("üniversite", List.of(
                "Bingöl Üniversitesi, 2007 yılında kurulmuş olup Doğu Anadolu Bölgesi'nin gelişmekte olan üniversitelerinden biridir.",
                "Üniversitemiz bünyesinde 10 fakülte, 4 yüksekokul, 5 meslek yüksekokulu ve 3 enstitü bulunmaktadır.",
                "Bingöl Üniversitesi'nin ana kampüsü şehir merkezine 5 km uzaklıktadır ve modern eğitim imkanları sunmaktadır."
        ));
        addConversationalResponses("akademik takvim", List.of(
                "Akademik takvim her yıl üniversitenin web sitesinde yayınlanır. İçeriğinde kayıt tarihleri, sınav haftaları, tatiller ve mezuniyet tarihleri yer alır.",
                "Derslerin başlangıç ve bitiş tarihlerini öğrenmek için akademik takvimi inceleyebilirsiniz.",
                "Final ve bütünleme sınav tarihleri de akademik takvimde belirtilmektedir, göz atmanızda fayda var."
        ));
        addConversationalResponses("obs", List.of(
                "OBS, öğrenci bilgi sistemidir. Ders kayıtları, notlar ve transkript gibi birçok bilgiye buradan ulaşabilirsiniz.",
                "OBS'ye üniversitenin resmi web sitesi üzerinden öğrenci numaranız ve şifrenizle giriş yapabilirsiniz.",
                "OBS'de sorun yaşarsanız öğrenci işleriyle iletişime geçebilirsiniz."
        ));
        addConversationalResponses("konaklama", List.of(
                "Üniversitemiz, KYK yurtlarıyla işbirliği içindedir ve kontenjanlar her yıl güncellenir.",
                "Yurt çıkmayan öğrenciler için kampüs çevresinde özel yurt ve kiralık daire imkanları mevcuttur.",
                "Yurtlara başvuru için e-Devlet üzerinden KYK başvuruları takip edilmelidir."
        ));
        addConversationalResponses("mobil uygulama", List.of(
                "Bingöl Üniversitesi'nin mobil uygulaması sayesinde duyurulara, yemek listelerine, OBS'ye ve kütüphane sistemine kolayca erişebilirsiniz.",
                "Uygulama Android ve iOS mağazalarında 'Bingöl Üniversitesi' adıyla yer almaktadır.",
                "Mobil uygulama üzerinden etkinlikleri ve sınav tarihlerini takip etmek oldukça kolay."
        ));
        addConversationalResponses("şifre", List.of(
                "OBS ya da e-posta şifrenizi unuttuysanız, bilişim destek birimi ile iletişime geçebilirsiniz.",
                "Şifre sıfırlama linki genellikle kayıtlı e-posta adresinize gönderilir.",
                "Şifrenizle ilgili sorun yaşarsanız, üniversitenin bilişim destek hattını arayabilirsiniz."
        ));
        addConversationalResponses("mezuniyet", List.of(
                "Mezuniyet için genel not ortalamanızın en az 2.00 olması ve tüm derslerden başarılı olmanız gerekmektedir.",
                "Mezuniyet töreni genellikle Haziran ayında gerçekleştirilir. Detaylı bilgiler öğrenci işlerinde duyurulur.",
                "Transkript ve diploma başvuruları mezuniyet sonrası otomatik olarak başlar."
        ));

        // Dersler hakkında genel bilgiler
        addConversationalResponses("ders", List.of(
                "Üniversitemizde derslere katılım çok önemlidir. Derslere düzenli katılım akademik başarınızı artırır.",
                "Ders programınızı öğrenci bilgi sisteminden kontrol edebilirsiniz.",
                "Seçmeli dersler için danışman hocanızla görüşmenizi öneririm."
        ));

        // Sınav ve notlar hakkında
        addConversationalResponses("sınav", List.of(
                "Sınavlarınızın tarihleri genellikle dönem başında ilan edilir ve öğrenci bilgi sisteminde yayınlanır.",
                "Final sınavlarına girebilmek için vize sınavlarından en az 45 puan almanız gerekmektedir.",
                "Sınav sonuçlarınızı öğrenci bilgi sisteminden takip edebilirsiniz."
        ));

        // Kampüs yaşamı
        addConversationalResponses("kampüs", List.of(
                "Kampüsümüzde kütüphane, yemekhane, spor tesisleri ve birçok sosyal alan bulunmaktadır.",
                "Üniversitemizde 50'den fazla öğrenci kulübü aktif olarak faaliyet göstermektedir.",
                "Kampüs içi ulaşım için düzenli ring servisleri hizmet vermektedir."
        ));

        // Yemek ve kafeterya
        addConversationalResponses("yemek", List.of(
                "Üniversitemizin merkez yemekhanesinde öğrencilere uygun fiyatlı ve besleyici menüler sunulmaktadır.",
                "Kampüs içinde çeşitli kafeteryalar ve kantinler bulunmaktadır.",
                "Yemek menülerini üniversitenin web sitesinden takip edebilirsiniz."
        ));

        // Barınma ve yurtlar
        addConversationalResponses("yurt", List.of(
                "Üniversitemizde KYK yurtları ve özel yurtlar bulunmaktadır.",
                "Yurt başvuruları genellikle Ağustos ayında başlamaktadır.",
                "Kampüs çevresinde öğrencilere uygun kiralık daireler de bulabilirsiniz."
        ));

        // Etkinlikler ve sosyal hayat
        addConversationalResponses("etkinlik", List.of(
                "Üniversitemizde düzenli olarak konferanslar, seminerler ve kültürel etkinlikler düzenlenmektedir.",
                "Öğrenci kulüplerimiz her dönem çeşitli etkinlikler organize etmektedir.",
                "Bahar şenlikleri her yıl Mayıs ayında gerçekleştirilmektedir."
        ));

        // Kütüphane hizmetleri
        addConversationalResponses("kütüphane", List.of(
                "Merkez kütüphanemiz hafta içi 08:00-22:00, hafta sonu 09:00-17:00 saatleri arasında hizmet vermektedir.",
                "Kütüphanemizde 100.000'den fazla basılı kaynak ve geniş bir elektronik kaynak koleksiyonu bulunmaktadır.",
                "Kütüphane kaynaklarına online erişim için üniversite hesabınızla giriş yapabilirsiniz."
        ));

        // Kariyer ve mezuniyet
        addConversationalResponses("kariyer", List.of(
                "Kariyer Merkezi'miz öğrencilere staj ve iş bulma konusunda destek vermektedir.",
                "Mezuniyet sonrası için CV hazırlama ve mülakat teknikleri hakkında düzenli eğitimler verilmektedir.",
                "Üniversitemiz birçok sektörden firmalarla işbirliği yaparak kariyer günleri düzenlemektedir."
        ));

        // Sağlık hizmetleri
        addConversationalResponses("sağlık", List.of(
                "Kampüsümüzde sağlık merkezi bulunmaktadır ve acil durumlar için hizmet vermektedir.",
                "Psikolojik danışmanlık hizmetlerimizden ücretsiz faydalanabilirsiniz.",
                "Sağlık sigortanızla ilgili sorularınız için öğrenci işleri birimine başvurabilirsiniz."
        ));

        // Spor imkanları
        addConversationalResponses("spor", List.of(
                "Üniversitemizde kapalı spor salonu, yüzme havuzu, fitness merkezi ve açık spor alanları bulunmaktadır.",
                "Öğrenciler spor tesislerinden ücretsiz veya indirimli olarak faydalanabilmektedir.",
                "Üniversite spor takımlarına katılmak için ilgili antrenörlerle iletişime geçebilirsiniz."
        ));

        // Öğrenci işleri
        addConversationalResponses("öğrenci işleri", List.of(
                "Öğrenci İşleri Daire Başkanlığı hafta içi 09:00-17:00 saatleri arasında hizmet vermektedir.",
                "Kayıt, belge ve transkript işlemleri için öğrenci işlerine başvurabilirsiniz.",
                "Birçok öğrenci işleri hizmetine e-devlet üzerinden de erişebilirsiniz."
        ));

        // Burslar ve finansal destek
        addConversationalResponses("burs", List.of(
                "Üniversitemizde başarı bursu, yemek bursu ve çeşitli özel burslar bulunmaktadır.",
                "Burs başvuruları genellikle eğitim yılı başında duyurulmaktadır.",
                "Kısmi zamanlı çalışma imkanları için kariyer merkezine başvurabilirsiniz."
        ));

        // Ulaşım
        addConversationalResponses("ulaşım", List.of(
                "Şehir merkezinden kampüse düzenli otobüs seferleri bulunmaktadır.",
                "Kampüs içi ring servisleri 15 dakika aralıklarla hizmet vermektedir.",
                "Bisiklet kullanımı için kampüs içinde özel parklar mevcuttur."
        ));

        // Günlük sohbet
        addConversationalResponses("hava", List.of(
                "Bugün hava oldukça güzel, umarım güzel bir gün geçiriyorsunuzdur.",
                "Hava durumunu kontrol etmenizi öneririm, son zamanlarda değişken olabiliyor.",
                "Hava nasıl olursa olsun, iyi bir gün geçirmenizi dilerim!"
        ));

        // Hobiler ve ilgi alanları
        addConversationalResponses("hobi", List.of(
                "Üniversitemizde çeşitli hobi kulüpleri bulunmaktadır. İlgi alanınıza göre bir kulübe katılabilirsiniz.",
                "Hobiler stresle başa çıkmanın en iyi yollarından biridir. Yeni bir hobi edinmeyi düşündünüz mü?",
                "Kampüsümüzde müzik, resim, tiyatro gibi sanatsal faaliyetler için imkanlar mevcuttur."
        ));

        // Teknoloji
        addConversationalResponses("teknoloji", List.of(
                "Üniversitemizde teknoloji laboratuvarları ve bilgisayar merkezleri öğrencilerin kullanımına açıktır.",
                "Teknoloji kulüplerimiz düzenli olarak workshop ve etkinlikler düzenlemektedir.",
                "Kampüs genelinde ücretsiz wifi hizmeti sunulmaktadır."
        ));

        // Motivasyon ve başarı
        addConversationalResponses("motivasyon", List.of(
                "Başarının anahtarı düzenli çalışma ve azimdir. Kendinize inanın!",
                "Hedeflerinizi küçük adımlara bölerek ilerlemeniz motivasyonunuzu artırabilir.",
                "Zorluklarla karşılaştığınızda danışman hocanızdan veya psikolojik danışmanlık servisinden destek alabilirsiniz."
        ));
    }

    private void initializeFallbackResponses() {
        fallbackResponses.add("Bu konuda daha fazla bilgi edinmek için size nasıl yardımcı olabilirim?");
        fallbackResponses.add("İlginç bir soru! Bu konuyu biraz daha açabilir misiniz?");
        fallbackResponses.add("Üzgünüm, bu konuda net bir bilgim yok. Başka bir şey sormak ister misiniz?");
        fallbackResponses.add("Bu sorunuzu tam olarak anlayamadım. Farklı bir şekilde sormak ister misiniz?");
        fallbackResponses.add("Bu konuda size daha iyi yardımcı olabilmek için biraz daha detay verebilir misiniz?");
        fallbackResponses.add("Şu anda bu konuda size yardımcı olamıyorum, ama üniversite hayatı hakkında başka sorularınız varsa yanıtlayabilirim.");
        fallbackResponses.add("Bu sorunun cevabını bilmiyorum, ama öğrenmek için not alıyorum. Başka nasıl yardımcı olabilirim?");
    }

    private void addStaticResponse(String[] keys, String response) {
        for (String key : keys) {
            staticResponses.put(key.toLowerCase(), response);
        }
    }

    private void addConversationalResponses(String keyword, List<String> responses) {
        conversationResponses.put(keyword.toLowerCase(), responses);
    }

    public String sendMessage(String username, String message) {
        message = message.toLowerCase().trim();

        Student student;
        try {
            student = studentManager.findBySchoolNumber(username);
        } catch (Exception e) {
            return "Öğrenci bilgilerine ulaşılamıyor, lütfen kullanıcı adınızı kontrol edin.";
        }

// Öğrenci bilgileri ile ilgili yanıtlar

// Ad bilgisi
        if (message.matches(".*(ben kimim|adımı söyle|adım ne|kimim|adım nedir|adım kim|adımı öğrenmek istiyorum|beni tanır mısın|beni tanıyor musun|kimsin|benim adım neydi|adımı hatırlıyor musun|adımı tekrarlar mısın|ismin ne|adımı söyler misin|ben kim olduğumu söyle|ben kiminim|benim kimliğim ne|adımı unuttum|adımı bana söyle|adımı bana hatırlat).*")) {
            return "Adınız: " + student.getFirstName() + " " + student.getLastName() +
                    ". Bingöl Üniversitesi'nde kayıtlı bir öğrencisiniz.";
        }

// Bölüm bilgisi
        if (message.matches(".*(bölümüm|hangi bölüm|bölümüm ne|bölüm adım|bölüm ismi|benim bölümüm|hangi bölümdeyim|bölüm adı nedir|bölüm bilgim|bölüm detayları|bölüm hakkında|bölümümü öğrenmek istiyorum|bölümüm hangisi|hangi bölüme kayıtlıyım|bölümümü söyle|bölüm adımı verir misin|bölüm neydi|okuduğum bölüm|bölüm adı ne|bölümünü söyler misin|bölüm hakkında bilgi|bölüm ne kadar önemli|bölümde hangi dersler var|bölüm programı nedir|bölüm kodu nedir|hangi alandayım|eğitim aldığım bölüm|bölümümle ilgili bilgi).*")) {
            return "Bölümünüz: " + (student.getDepartment() != null ? student.getDepartment().name() : "Bölüm bilgisi yok") +
                    ". Bu bölümde eğitim görüyorsunuz ve mezun olduğunuzda bu alanda uzmanlaşmış olacaksınız.";
        }

// Fakülte bilgisi
        if (message.matches(".*(fakültem|hangi fakülte|fakülte adım|fakülte ismi|benim fakültem|fakültedeyim|fakülte nedir|fakülte adı|fakülte hangi|hangi fakültedeyim|fakültem nerede|fakültem hangisi|fakülte bilgim|fakülte detayları|fakülte hakkında).*")) {
            return "Fakülteniz: " + (student.getFaculty() != null ? student.getFaculty().name() : "Fakülte bilgisi yok") +
                    ". Fakültenizin dekanı ve yönetimi hakkında bilgi almak için fakültenizin web sayfasını ziyaret edebilirsiniz.";
        }

// Sınıf bilgisi
        if (message.matches(".*(sınıfım|kaçıncı sınıf|hangi sınıftayım|ben kaçıncı sınıftayım|sınıf seviyem|şu an kaçıncı sınıftayım|okuldaki sınıfım|eğitim seviyem|sınıfım ne|hangi yıl).*")) {
            return "Sınıfınız: " + (student.getGrade() != null ? student.getGrade().name() : "Sınıf bilgisi yok") +
                    ". Her sınıf seviyesinde farklı dersler ve sorumluluklar bulunmaktadır.";
        }

// Doğum tarihi ve yaş bilgisi
        if (message.matches(".*(yaşım kaç|kaç yaşındayım|yaşım|doğum tarihim|doğum günüm ne|doğum günü|doğumum ne zaman|ne zaman doğdum|doğum tarihi|kaç yılında doğdum|doğum bilgilerim|doğum|yaş bilgisi).*")) {
            if (student.getBirthDate() != null) {
                return "Doğum tarihiniz: " + student.getBirthDate().format(DateTimeFormatter.ofPattern("dd MMMM yyyy")) +
                        ". Bu bilgi kişisel dosyanızda güvenli bir şekilde saklanmaktadır.";
            } else {
                return "Doğum tarihi bilgisi mevcut değil. Bu bilgiyi öğrenci işlerine başvurarak güncelleyebilirsiniz.";
            }
        }

// Popülerlik bilgisi
        if (message.matches(".*(popülerlik|popüler miyim|popülerlik puanı|ne kadar popülerim|popülerlik skoru|popülaritem|ünlülük|ne kadar tanınıyorum|kaç puanım var|sosyal puanım|sosyal etki puanı|popülerlik seviyem|sosyal statüm|etkileşim puanı).*")) {
            return "Popülerlik puanınız: " + student.getPopularityScore() +
                    ". Bu puan sosyal medya etkileşimleriniz ve platform içi aktivitelerinize göre hesaplanmaktadır.";
        }

// Not bilgisi
        if (message.matches(".*(not ortalamam|not ortalaması|not ortalaması kaç|notlarım|gpa|gpa kaç|ortalama kaç|notum kaç|ders notu|ders notlarım|akademik ortalama|transkript|not bilgim|not dökümü|puan ortalamam|puanım|puan ortalaması|ortalama bilgisi|karnem|dönem ortalaması|genel ortalama|ders başarı durumu|başarı notu|not sistemi).*")) {
            return "Not ortalamanız hakkında bilgi için öğrenci bilgi sistemini kontrol etmenizi öneririm. " +
                    "Derslerinizin detaylı not dökümünü oradan görebilirsiniz.";
        }

        // Haber sorguları için regex pattern - daha özel ve ayrıntılı sorgu tespiti
        Pattern haberDeseni = Pattern.compile(".*(haberler|haberleri|güncel haberler|son haberler|kampüs haberleri|kampüste neler oluyor|neler oldu|en son haberler|son etkinlikler|etkinlik|etkinlikler|son gelişmeler|yakın tarihli etkinlikler|seminer|seminerler|konferans|konferanslar|tanıtım|fuar|ödül töreni|açılış|üniversite gazetesi|üniversitenin son durumu|rektör|dekan|bölüm başkanı).*", Pattern.CASE_INSENSITIVE);
        if (haberDeseni.matcher(message).find() && !message.contains("duyuru")) {
            try {
                List<News> haberler = newsScraper.getLatestNews(5);
                return newsScraper.formatNewsToString(haberler);
            } catch (Exception e) {
                return "Haberler alınırken bir sorun oluştu. Lütfen daha sonra tekrar deneyin.";
            }
        }
        
        // Duyuru sorguları için regex pattern - daha özel ve ayrıntılı sorgu tespiti
        Pattern duyuruDeseni = Pattern.compile(".*(duyurular|duyuruları|ilan|ilanlar|sınavlar|sınav tarihleri|erasmus|farabi|mevlana|yaz okulu|ders kayıtları|kayıt tarihleri|başvuru tarihleri|akademik takvim|duyuru var mı|yeni duyuru|güncel duyurular|son ilan|bölüm duyuruları|fakülte duyuruları|okulun duyuruları|yönetim duyuruları|burs|önemli duyuru|idari duyuru|resmi duyuru|açık öğretim|öğrenci işleri duyurusu|dgs|yks).*", Pattern.CASE_INSENSITIVE);
        if (duyuruDeseni.matcher(message).find()) {
            try {
                List<News> duyurular = newsScraper.getLatestAnnouncements(5);
                return newsScraper.formatAnnouncementsToString(duyurular);
            } catch (Exception e) {
                return "Duyurular alınırken bir sorun oluştu. Lütfen daha sonra tekrar deneyin.";
            }
        }
        
        // Hem haber hem duyuru için birleşik sorgu
        if (message.matches(".*(hem haber hem duyuru|haberler ve duyurular|duyurular ve haberler|son gelişmeler ve duyurular|neler oluyor|tüm gelişmeler|güncel bilgiler|her şey|haber duyuru).*")) {
            try {
                List<News> haberler = newsScraper.getLatestNews(3);
                List<News> duyurular = newsScraper.getLatestAnnouncements(3);
                
                String haberMetni = newsScraper.formatNewsToString(haberler);
                String duyuruMetni = newsScraper.formatAnnouncementsToString(duyurular);
                
                return haberMetni + "\n\n---------------\n\n" + duyuruMetni;
            } catch (Exception e) {
                return "Haberler ve duyurular alınırken bir sorun oluştu. Lütfen daha sonra tekrar deneyin.";
            }
        }

        // Yemek menüsü ile ilgili sorgular
        if (message.matches(".*(yemek|menü|menu|menusu|menüsü|bugün ne yenir|bugün ne var|bugünkü yemek|bugünkü menü|bugün yemek ne|yemekte ne var|ne yemek var|ne yeniyor|ne çıkıyor|akşam yemeği|öğle yemeği|akşam menüsü|öğle menüsü|yemek listesi|yemekler ne|üniversite yemeği|kampüs yemeği|kampüste ne var|bugün ne çıkıyor|bugün çıkan yemek|çıkacak yemek|yemek bilgisi|yemek bilgileri|yemek var mı|menü var mı).*")) {

            LocalDate hedefTarih = LocalDate.now();

            // Tarih belirtilmiş mi? ("21 Mayıs", "21.05", "21-05-2025", vs.)
            Pattern tarihSayisalDeseni = Pattern.compile("(\\d{1,2}[./\\-\\s]\\d{1,2}([./\\-\\s]\\d{2,4})?)");
            Pattern tarihKelimeDeseni = Pattern.compile("(\\d{1,2})\\s*(ocak|şubat|mart|nisan|mayıs|haziran|temmuz|ağustos|eylül|ekim|kasım|aralık)", Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE);
            Matcher matcherSayisal = tarihSayisalDeseni.matcher(message);
            Matcher matcherKelime = tarihKelimeDeseni.matcher(message);

            if (message.contains("yarın") || message.contains("yarinki") || message.contains("yarının")) {
                hedefTarih = hedefTarih.plusDays(1);
            } else if (message.contains("bugün") || message.contains("bugunku") || message.contains("bugünün")) {
                hedefTarih = LocalDate.now();
            } else if (matcherSayisal.find()) {
                String tarihMetni = matcherSayisal.group(1).replaceAll("[\\s\\-]", ".");
                DateTimeFormatter[] olasiFormatlar = new DateTimeFormatter[]{
                        DateTimeFormatter.ofPattern("d.M.yyyy"),
                        DateTimeFormatter.ofPattern("d.M.yy"),
                        DateTimeFormatter.ofPattern("d.M")
                };
                boolean parseBasarili = false;
                for (DateTimeFormatter format : olasiFormatlar) {
                    try {
                        LocalDate parsed = LocalDate.parse(tarihMetni, format);
                        if (parsed.getYear() < 100) {
                            parsed = parsed.withYear(LocalDate.now().getYear());
                        }
                        hedefTarih = parsed;
                        parseBasarili = true;
                        break;
                    } catch (Exception ignored) {}
                }
                if (!parseBasarili) {
                    return "Belirttiğiniz tarih anlaşılamadı. Lütfen '20.05.2025' veya '20 Mayıs' gibi bir format kullanın.";
                }
            } else if (matcherKelime.find()) {
                int gun = Integer.parseInt(matcherKelime.group(1));
                String ayStr = matcherKelime.group(2).toLowerCase(Locale.forLanguageTag("tr"));

                Map<String, Integer> ayMap = Map.ofEntries(
                        Map.entry("ocak", 1), Map.entry("şubat", 2), Map.entry("mart", 3), Map.entry("nisan", 4),
                        Map.entry("mayıs", 5), Map.entry("haziran", 6), Map.entry("temmuz", 7), Map.entry("ağustos", 8),
                        Map.entry("eylül", 9), Map.entry("ekim", 10), Map.entry("kasım", 11), Map.entry("aralık", 12)
                );

                Integer ay = ayMap.get(ayStr);
                if (ay != null) {
                    hedefTarih = LocalDate.of(LocalDate.now().getYear(), ay, gun);
                } else {
                    return "Ay ismi tanınamadı: " + ayStr;
                }
            }

            // Menü getir
            try {
                FoodMenu menu = yemekMenusuService.getMenusuByTarih(hedefTarih);
                DateTimeFormatter gosterimFormati = DateTimeFormatter.ofPattern("dd MMMM yyyy", new Locale("tr"));
                return hedefTarih.format(gosterimFormati) + " tarihli yemek menüsü:\n" +
                        "- Ana Yemek: " + menu.getAnaYemek() + "\n" +
                        "- Yan Yemek: " + menu.getYanYemek() + "\n" +
                        "- Çorba: " + menu.getCorba() + "\n" +
                        "- Tatlı: " + menu.getTatli();
            } catch (Exception e) {
                DateTimeFormatter gosterimFormati = DateTimeFormatter.ofPattern("dd MMMM yyyy", new Locale("tr"));
                String tarihStr = hedefTarih.format(gosterimFormati);
                return tarihStr + " tarihinde yemek menüsü bulunamadı. Muhtemelen o gün üniversitede tatil veya yemek servisi yapılmıyor.";
            }
        }


// Hava durumu ile ilgili sorgular
        Pattern havaDeseni = Pattern.compile(".*(hava nasıl|hava durumu|şu an hava|şuanki hava|hava raporu|hava sıcaklığı|hava kaç derece|hava ne durumda|bugün hava|bugünkü hava|yarın hava|yarınki hava|şehrin havası|kaç derece|gündüz nasıl|gece nasıl|gündüz hava|gece hava|hava durumu nedir|şimdi hava|şu anki sıcaklık|şu anki hava durumu|şu an kaç derece|şu anda hava|hava bugün nasıl|bugün kaç derece|bugünkü sıcaklık|hava bilgisi|hava hakkında|hava verisi|hava bilgileri|dışarısı nasıl|hava soğuk mu|hava sıcak mı|hava iyi mi|hava kötü mü|hava açık mı|hava yağmurlu mu|hava kapalı mı).*", Pattern.CASE_INSENSITIVE);
        if (havaDeseni.matcher(message).find()) {
            String sehir = "Bingöl"; // varsayılan şehir

            // Mesajdan şehir ismini çekmeye çalış
            // Örn: "Ankara'da hava nasıl", "İstanbul hava durumu"
            Pattern sehirDeseni = Pattern.compile("\\b(?:hava|durumu|sıcaklığı|kaç derece)?(?:\\s*ne|nasıl)?(?:\\s*için)?\\s*(\\p{L}{3,})\\b", Pattern.CASE_INSENSITIVE);
            Matcher matcher = sehirDeseni.matcher(message);
            while (matcher.find()) {
                String olasiSehir = matcher.group(1).trim();
                // Türkiye şehir adı gibi görünüyorsa al (alternatif olarak sabit şehir listesi ile kontrol edebilirsin)
                if (Character.isUpperCase(olasiSehir.charAt(0))) {
                    sehir = olasiSehir;
                    break;
                }
            }

            // Mesajda 'gündüz' veya 'gece' geçiyor mu?
            boolean gunduzIstek = message.toLowerCase().contains("gündüz");
            boolean geceIstek = message.toLowerCase().contains("gece");

            try {
                String sonuc = havaDurumuService.getHavaDurumu(sehir);

                if (geceIstek && sonuc.contains("Gündüz")) {
                    return "Şu anda gündüz olduğu için gece bilgisi mevcut değil. Ancak mevcut durum şöyle:\n\n" + sonuc;
                } else if (gunduzIstek && sonuc.contains("Gece")) {
                    return "Şu anda gece olduğu için gündüz bilgisi mevcut değil. Ancak mevcut durum şöyle:\n\n" + sonuc;
                }

                return sonuc;
            } catch (Exception e) {
                return "Hava durumu bilgisi alınırken bir hata oluştu. Lütfen şehir ismini doğru yazdığınızdan emin olun.";
            }

        }

        // Statik yanıtlar kontrolü
        for (Map.Entry<String, String> entry : staticResponses.entrySet()) {
            if (message.contains(entry.getKey())) {
                if (entry.getKey().contains("saat")) {
                    return String.format(entry.getValue(), LocalTime.now().format(DateTimeFormatter.ofPattern("HH:mm")));
                }
                return entry.getValue();
            }
        }

        // Konuşma yanıtları kontrolü
        for (Map.Entry<String, List<String>> entry : conversationResponses.entrySet()) {
            if (message.contains(entry.getKey())) {
                List<String> responses = entry.getValue();
                return responses.get(random.nextInt(responses.size()));
            }
        }

        // Anlaşılamayan mesajlar için
        return fallbackResponses.get(random.nextInt(fallbackResponses.size()));
    }
}

