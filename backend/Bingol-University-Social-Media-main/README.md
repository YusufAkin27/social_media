# Bingol University Campus

Bingol University Campus uygulaması, Bingöl Üniversitesi öğrencileri için geliştirilmiş bir sosyal medya platformudur. Kampüs yaşamını daha etkileşimli hale getirmeyi amaçlayan bu uygulama, öğrencilere birbirleriyle hikaye paylaşımı, gönderi oluşturma, beğeni yapma, yorum bırakma, takip etme ve engelleme gibi sosyal medya özellikleri sunar.

---

## Özellikler

### Kullanıcı Profili
- Öğrenciler, kendilerine özel bir kullanıcı adı, fotoğraf ve biyografi bilgisiyle kişisel profiller oluşturabilirler.

### Gönderi Paylaşımı
- Öğrenciler, fotoğraf, yazı ve hikayeler gibi içerikleri paylaşabilirler.

### Beğeni ve Yorum
- Paylaşılan gönderi ve hikayelere beğeni yapabilir ve yorum bırakabilirler.

### Takip Etme
- Öğrenciler birbirlerini takip edebilir ve takip ettikleri kişilerin paylaşımlarını görebilirler.

### Engelleme
- Öğrenciler, takip ettikleri kişileri engelleyebilir ve engellenen kullanıcıların içeriklerine erişimi engelleyebilirler.

### Özel Paylaşımlar
- Kullanıcılar, paylaşımlarını yalnızca takipçileriyle sınırlı tutabilir.

### Hikaye Paylaşımı
- Öğrenciler, hikaye oluşturabilir ve bunları takipçileriyle paylaşabilirler.

### Anlık Bildirimler
- Yorumlar, beğeniler ve takip bildirimleri kullanıcıya anlık olarak bildirilir.

---

## Teknolojiler

- **Backend:**
    - **Java:** 21 SDK sürümü (Amazon Corretto)
    - **Spring Boot:** Uygulama geliştirme ve sunucu yönetimi
    - **Spring Security:** Kimlik doğrulama ve yetkilendirme için JWT tabanlı güvenlik
    - **Spring Data JPA:** Veritabanı işlemleri için ORM (PostgreSQL ile entegrasyon)
    - **Spring Boot Starter WebSocket:** Anlık bildirimler ve gerçek zamanlı etkileşim için

- **Veritabanı:**
    - **PostgreSQL:** İlişkisel veritabanı yönetim sistemi

- **Kimlik Doğrulama:**
    - **JWT (JSON Web Token):** Kullanıcı kimlik doğrulaması ve güvenli erişim sağlama

- **Hikaye Paylaşımı:**
    - **AWS S3:** Fotoğraf ve medya dosyalarını depolamak için bulut tabanlı depolama çözümü

- **Diğer Bağımlılıklar:**
    - **Cloudinary:** Görsel ve video yükleme ve yönetim için
    - **Firebase Admin SDK:** Gerçek zamanlı veritabanı ve bildirim yönetimi
    - **Apache POI:** Excel dosyaları ile etkileşim için
    - **Zxing:** QR kod oluşturma ve okuma için

---

## Kurulum

### Gereksinimler

- **Java SDK 21** (Amazon Corretto)
- **PostgreSQL** veritabanı
- **Maven** (Bağımlılık yönetimi için)
- **Node.js** ve **npm** (Frontend için)

### Projeyi Çalıştırmak İçin Adımlar

#### 1. Bağımlılıkları Yükleyin

Proje dizininde aşağıdaki komutu çalıştırarak bağımlılıkları yükleyin:

```bash
mvn clean install
