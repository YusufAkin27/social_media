package bingol.campus.story.repository;

import bingol.campus.story.entity.StoryViewer;
import bingol.campus.student.entity.Student;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface StoryViewerRepository extends JpaRepository<StoryViewer, UUID> {
    List<StoryViewer> findViewedStoryIdsByStudent(Student student);

}
