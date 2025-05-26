package bingol.campus.like.repository;

import bingol.campus.like.entity.Like;
import bingol.campus.post.entity.Post;
import bingol.campus.story.entity.Story;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public interface LikeRepository extends JpaRepository<Like,Long> {
    List<Like> findByPostAndLikedAtAfter(Post post, LocalDateTime parsedDateTime);

    Page<Like> findByPost(Post post, Pageable pageable);

    Page<Like> findByStory(Story story, Pageable pageRequest);

    long countByCreatedAt(LocalDateTime today);
}
