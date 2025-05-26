package bingol.campus.chatbot.manager;

import bingol.campus.chatbot.entity.News;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

@Service
public class NewsScraper {
    private static final Logger logger = Logger.getLogger(NewsScraper.class.getName());
    private static final String UNIVERSITY_URL = "https://www.bingol.edu.tr/tr";

    /**
     * Bingöl Üniversitesi web sitesindeki son haberleri çeker
     * @param count Kaç haber getirileceği
     * @return Haber listesi
     */
    public List<News> getLatestNews(int count) {
        try {
            Document doc = Jsoup.connect(UNIVERSITY_URL).get();
            List<News> haberler = new ArrayList<>();
            
            // İnceleme sonucu - Ana sayfadaki haber öğelerini seç
            Elements newsElements = doc.select(".container .home-page-news .news-item");
            
            // Ana sayfadaki haberler yoksa alternatif seçicileri dene
            if (newsElements.isEmpty()) {
                newsElements = doc.select(".news-list-item");
            }
            if (newsElements.isEmpty()) {
                newsElements = doc.select(".haberler .row .col-md-4");
            }
            if (newsElements.isEmpty()) {
                // Tüm başlıkları ve altyazıları olan div'leri kontrol et
                newsElements = doc.select("div:has(h3):has(p):has(a)");
            }
            
            // Haber listesi yoksa doğrudan haber içeriğini bul
            if (newsElements.isEmpty()) {
                Elements allNewsLinks = doc.select("a:contains(Rektörümüz), a:contains(Üniversitemizde), a:contains(Bingöl Üniversitesi)");
                for (Element element : allNewsLinks) {
                    String baslik = element.text().trim();
                    String link = element.absUrl("href");
                    
                    if (!baslik.isEmpty() && link.contains("bingol.edu.tr")) {
                        haberler.add(new News(baslik, link));
                        if (haberler.size() >= count) {
                            break;
                        }
                    }
                }
                return haberler;
            }
            
            for (Element element : newsElements) {
                String baslik = "";
                String link = "";
                
                // Başlık için öğeyi bul
                Element titleElement = element.selectFirst("h3, h4, .news-title, .card-title, .title");
                if (titleElement != null) {
                    baslik = titleElement.text().trim();
                } else {
                    Element linkElement = element.selectFirst("a");
                    if (linkElement != null) {
                        baslik = linkElement.text().trim();
                    } else {
                        // Başlık bulunamazsa tam metni al
                        baslik = element.text().trim();
                    }
                }
                
                // Link için öğeyi bul
                Element linkElement = element.selectFirst("a");
                if (linkElement != null) {
                    link = linkElement.absUrl("href");
                    if (link.isEmpty()) {
                        link = UNIVERSITY_URL + linkElement.attr("href");
                    }
                }
                
                // Boş olmayan ve yeterince uzun başlıkları ekle
                if (!baslik.isEmpty() && baslik.length() > 3) {
                    haberler.add(new News(baslik, link));
                    if (haberler.size() >= count) {
                        break;
                    }
                }
            }
            
            return haberler;
        } catch (IOException e) {
            logger.log(Level.WARNING, "Haberler alınırken hata oluştu: " + e.getMessage(), e);
            return Collections.emptyList();
        }
    }

    /**
     * Bingöl Üniversitesi web sitesindeki son duyuruları çeker
     * @param count Kaç duyuru getirileceği
     * @return Duyuru listesi
     */
    public List<News> getLatestAnnouncements(int count) {
        try {
            Document doc = Jsoup.connect(UNIVERSITY_URL).get();
            List<News> duyurular = new ArrayList<>();
            
            // İnceleme sonucu - Ana sayfadaki duyuru öğelerini seç
            Elements announcementElements = doc.select(".container .home-page-announcements .announcement-item");
            
            // Ana sayfadaki duyurular yoksa alternatif seçicileri dene
            if (announcementElements.isEmpty()) {
                announcementElements = doc.select(".announcement-list-item");
            }
            if (announcementElements.isEmpty()) {
                announcementElements = doc.select(".duyurular .row .col-md-4");
            }
            if (announcementElements.isEmpty()) {
                announcementElements = doc.select("div.duyurular li, div.announcements li");
            }
            
            // Duyuru listesi yoksa doğrudan duyuru bölümünü bul
            if (announcementElements.isEmpty()) {
                Elements allAnnouncementLinks = doc.select("a:contains(Duyuru), a:contains(Erasmus), a:contains(Sınav), a:contains(YKS), a:contains(İlan)");
                for (Element element : allAnnouncementLinks) {
                    String baslik = element.text().trim();
                    String link = element.absUrl("href");
                    
                    if (!baslik.isEmpty() && link.contains("bingol.edu.tr") && 
                        (baslik.contains("Duyuru") || baslik.contains("İlan") || baslik.contains("Erasmus"))) {
                        duyurular.add(new News(baslik, link));
                        if (duyurular.size() >= count) {
                            break;
                        }
                    }
                }
                return duyurular;
            }
            
            for (Element element : announcementElements) {
                String baslik = "";
                String link = "";
                
                // Duyuru metni arama
                Element titleElement = element.selectFirst("h3, h4, .announcement-title, .card-title, .title");
                if (titleElement != null) {
                    baslik = titleElement.text().trim();
                } else {
                    Element linkElement = element.selectFirst("a");
                    if (linkElement != null) {
                        baslik = linkElement.text().trim();
                    } else {
                        // Başlık bulunamazsa tam metni al
                        baslik = element.text().trim();
                    }
                }
                
                // Duyuru linki arama
                Element linkElement = element.selectFirst("a");
                if (linkElement != null) {
                    link = linkElement.absUrl("href");
                    if (link.isEmpty()) {
                        link = UNIVERSITY_URL + linkElement.attr("href");
                    }
                }
                
                // Boş olmayan ve yeterince uzun başlıkları ekle
                if (!baslik.isEmpty() && baslik.length() > 3) {
                    duyurular.add(new News(baslik, link));
                    if (duyurular.size() >= count) {
                        break;
                    }
                }
            }
            
            return duyurular;
        } catch (IOException e) {
            logger.log(Level.WARNING, "Duyurular alınırken hata oluştu: " + e.getMessage(), e);
            return Collections.emptyList();
        }
    }
    
    /**
     * Haber listesini okunabilir bir metin formatına dönüştürür
     */
    public String formatNewsToString(List<News> haberler) {
        if (haberler.isEmpty()) {
            return "Haber bulunamadı. Üniversite web sitesine erişimde bir sorun olabilir.";
        }
        
        StringBuilder sb = new StringBuilder();
        sb.append("📰 BİNGÖL ÜNİVERSİTESİ - SON HABERLER\n\n");
        
        for (int i = 0; i < haberler.size(); i++) {
            News news = haberler.get(i);
            sb.append(i + 1).append(" 》 ").append(news.getBaslik());
            if (news.getLink() != null && !news.getLink().isEmpty()) {
                sb.append("\n   🔗 ").append(news.getLink());
            }
            sb.append("\n\n");
        }
        
        sb.append("Daha fazla haber için üniversite web sitesini ziyaret edebilirsiniz:\n");
        sb.append(UNIVERSITY_URL);
        return sb.toString();
    }
    
    /**
     * Duyuru listesini okunabilir bir metin formatına dönüştürür
     */
    public String formatAnnouncementsToString(List<News> duyurular) {
        if (duyurular.isEmpty()) {
            return "Duyuru bulunamadı. Üniversite web sitesine erişimde bir sorun olabilir.";
        }
        
        StringBuilder sb = new StringBuilder();
        sb.append("📢 BİNGÖL ÜNİVERSİTESİ - SON DUYURULAR\n\n");
        
        for (int i = 0; i < duyurular.size(); i++) {
            News duyuru = duyurular.get(i);
            sb.append(i + 1).append(" 》 ").append(duyuru.getBaslik());
            if (duyuru.getLink() != null && !duyuru.getLink().isEmpty()) {
                sb.append("\n   🔗 ").append(duyuru.getLink());
            }
            sb.append("\n\n");
        }
        
        sb.append("Daha fazla duyuru için üniversite web sitesini ziyaret edebilirsiniz:\n");
        sb.append(UNIVERSITY_URL);
        return sb.toString();
    }
}
