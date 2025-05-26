package bingol.campus.chatbot.manager;

import bingol.campus.chatbot.entity.FoodMenu;
import bingol.campus.chatbot.entity.FoodMenuRepository;
import lombok.RequiredArgsConstructor;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.select.Elements;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
@RequiredArgsConstructor
public class YemekMenusuService {

    private final FoodMenuRepository repository;

    public FoodMenu getBugununMenusu() {
        return getMenusuByTarih(LocalDate.now());
    }

    public FoodMenu getYarininMenusu() {
        return getMenusuByTarih(LocalDate.now().plusDays(1));
    }

    public FoodMenu getMenusuByTarih(LocalDate tarih) {
        // Veritabanında varsa döndür
        Optional<FoodMenu> optional = repository.findByTarih(tarih);
        if (optional.isPresent()) {
            return optional.get();
        }

        // Değilse tüm siteyi kazı, listeyi veritabanına kaydet
        List<FoodMenu> scrapedMenus = scrapeTumMenuler();
        for (FoodMenu menu : scrapedMenus) {
            repository.findByTarih(menu.getTarih()).orElseGet(() -> repository.save(menu));
        }

        // Kazıma sonrası tekrar veri tabanından getir
        return repository.findByTarih(tarih)
                .orElseThrow(() -> new RuntimeException(tarih + " için yemek menüsü bulunamadı."));
    }

    private List<FoodMenu> scrapeTumMenuler() {
        String url = "https://sks.bingol.edu.tr/yemek-listesi";
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd.MM.yyyy");
        List<FoodMenu> menuler = new ArrayList<>();

        try {
            Document doc = Jsoup.connect(url).get();
            Elements satirlar = doc.select("table tr");

            for (int i = 1; i < satirlar.size(); i++) {
                Elements sutunlar = satirlar.get(i).select("td");
                if (sutunlar.size() < 5) continue;

                String tarihStr = sutunlar.get(0).text().trim();
                LocalDate tarih;
                try {
                    tarih = LocalDate.parse(tarihStr, formatter);
                } catch (Exception e) {
                    continue; // Geçersiz tarih
                }

                FoodMenu menu = FoodMenu.builder()
                        .tarih(tarih)
                        .anaYemek(sutunlar.get(1).text().trim())
                        .yanYemek(sutunlar.get(2).text().trim())
                        .corba(sutunlar.get(3).text().trim())
                        .tatli(sutunlar.get(4).text().trim())
                        .build();

                menuler.add(menu);
            }

        } catch (IOException e) {
            throw new RuntimeException("Yemek listesi alınamadı: " + e.getMessage());
        }

        return menuler;
    }
}
