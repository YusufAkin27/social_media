package bingol.campus.chatbot.entity;

public class News {
    private String baslik;
    private String link;

    public News(String baslik, String link) {
        this.baslik = baslik;
        this.link = link;
    }

    public String getBaslik() {
        return baslik;
    }

    public String getLink() {
        return link;
    }
}
