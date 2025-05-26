package bingol.campus.chatbot.manager;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.LocalTime;
import java.time.format.DateTimeFormatter;

@Service
public class HavaDurumuService {

    private static final String API_KEY = "ab8bc9c9c97f4459810203618251505";
    private static final String BASE_URL = "https://api.weatherapi.com/v1/current.json";
    private static final String VARSAYILAN_SEHIR = "Bingol";

    public String getHavaDurumu(String sehir) {
        // Boş, anlamsız ya da null girişlerde varsayılan şehir Bingöl
        if (sehir == null || sehir.isBlank()
                || sehir.toLowerCase().matches(".*\\bhava\\b.*") || sehir.length() < 3) {
            sehir = VARSAYILAN_SEHIR;
        }

        String temizSehir = normalizeSehir(sehir);
        String url = String.format("%s?key=%s&q=%s&lang=tr", BASE_URL, API_KEY, temizSehir);

        try {
            RestTemplate restTemplate = new RestTemplate();
            ResponseEntity<String> response = restTemplate.getForEntity(url, String.class);

            if (!response.getStatusCode().is2xxSuccessful() || response.getBody() == null) {
                return "❌ Hava durumu servisine ulaşılamadı. Lütfen daha sonra tekrar deneyin.";
            }

            ObjectMapper mapper = new ObjectMapper();
            JsonNode root = mapper.readTree(response.getBody());

            String bolge = root.path("location").path("name").asText();
            String ulke = root.path("location").path("country").asText();
            String guncelleme = root.path("current").path("last_updated").asText();
            String saat = guncelleme.split(" ")[1];

            String durum = root.path("current").path("condition").path("text").asText();
            double sicaklik = root.path("current").path("temp_c").asDouble();
            double hissedilen = root.path("current").path("feelslike_c").asDouble();
            int nem = root.path("current").path("humidity").asInt();
            double ruzgar = root.path("current").path("wind_kph").asDouble();
            boolean gunduzMu = root.path("current").path("is_day").asInt() == 1;

            String saatBilgisi = LocalTime.parse(saat, DateTimeFormatter.ofPattern("HH:mm"))
                    .format(DateTimeFormatter.ofPattern("HH:mm"));

            return String.format("""
                    📍 %s, %s için güncel hava durumu:

                    🌤️ Durum: %s
                    🌡️ Sıcaklık: %.1f°C (Hissedilen: %.1f°C)
                    💧 Nem: %d%%
                    🌬️ Rüzgar: %.1f km/s
                    🕒 Güncellenme saati: %s (%s)
                    """,
                    bolge, ulke,
                    durum, sicaklik, hissedilen, nem, ruzgar,
                    saatBilgisi, gunduzMu ? "Gündüz" : "Gece"
            );

        } catch (Exception e) {
            return "⚠️ Hava durumu bilgisi alınamadı. Lütfen şehir adını kontrol edin veya daha sonra tekrar deneyin.\n\nHata: " + e.getMessage();
        }
    }

    // Türkçe karakterleri ve boşlukları normalize eden yardımcı metot
    private String normalizeSehir(String sehir) {
        return sehir.trim()
                .replace("ç", "c")
                .replace("ğ", "g")
                .replace("ı", "i")
                .replace("ö", "o")
                .replace("ş", "s")
                .replace("ü", "u")
                .replaceAll("\\s+", ""); // tüm boşlukları kaldır
    }
}
