package bingol.campus.story.repository;

import bingol.campus.story.entity.FeaturedStory;
import bingol.campus.story.entity.Story;
import bingol.campus.student.entity.Student;
import com.google.api.gax.rpc.ServerStream;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface FeaturedStoryRepository extends JpaRepository<FeaturedStory, UUID> {

    @Query("SELECT f FROM FeaturedStory f JOIN f.stories s WHERE f.student = :student AND s = :story")
    Optional<FeaturedStory> findFeaturedStoryByStudentAndStory(@Param("student") Student student, @Param("story") Story story);

}
