package bingol.campus.post.business;

import bingol.campus.post.entity.Post;
import bingol.campus.post.repository.PostRepository;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class PopularityPostService {

    private final PostRepository postRepository;

    public PopularityPostService(PostRepository postRepository) {
        this.postRepository = postRepository;
    }

    // Popülerlik skorunu hesaplayan metod
    private long calculatePopularityScore(Post post) {
        int likesCount = post.getLikes().size(); // Beğeni sayısı
        int commentsCount = post.getComments().size(); // Yorum sayısı
        int taggedCount = post.getTaggedPersons().size(); // Etiketlenen kişi sayısı

        // Popülerlik skoru hesaplama formülü
        return likesCount * 3L + commentsCount * 2L + taggedCount;
    }

    // Her gün saat 05:00'te gönderilerin popülerlik skorlarını günceller
    @Transactional
    @Scheduled(cron = "0 0 4 * * ?") // Her gün saat 05:00'te çalışır
    public void updatePostPopularityScores() {
        List<Post> posts = postRepository.findAll();
        for (Post post : posts) {
            long popularityScore = calculatePopularityScore(post);
            post.setPopularityScore(popularityScore);
            postRepository.save(post);
        }
    }

    // En popüler gönderileri belirli bir limit ile getirir
    public List<Post> getTopPopularPosts(int limit) {
        return postRepository.findAll()
                .stream()
                .sorted((p1, p2) -> Long.compare(p2.getPopularityScore(), p1.getPopularityScore())) // Skora göre sıralama
                .limit(limit) // Belirtilen sayı kadar gönderi getir
                .collect(Collectors.toList());
    }
}
