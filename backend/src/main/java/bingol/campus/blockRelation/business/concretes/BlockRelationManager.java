package bingol.campus.blockRelation.business.concretes;

import bingol.campus.blockRelation.business.abstracts.BlockRelationService;
import bingol.campus.blockRelation.core.converter.BlockRelationConverter;
import bingol.campus.blockRelation.core.exceptions.AlreadyBlockUserException;
import bingol.campus.blockRelation.core.exceptions.BlockUserNotFoundException;
import bingol.campus.blockRelation.core.response.BlockUserDTO;
import bingol.campus.blockRelation.entity.BlockRelation;
import bingol.campus.blockRelation.repository.BlockRelationRepository;
import bingol.campus.comment.entity.Comment;
import bingol.campus.comment.repository.CommentRepository;
import bingol.campus.followRelation.repository.FollowRelationRepository;
import bingol.campus.friendRequest.repository.FriendRequestRepository;
import bingol.campus.like.entity.Like;
import bingol.campus.like.repository.LikeRepository;
import bingol.campus.post.entity.Post;
import bingol.campus.post.repository.PostRepository;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;
import bingol.campus.story.entity.Story;
import bingol.campus.story.repository.StoryRepository;
import bingol.campus.student.entity.Student;
import bingol.campus.student.exceptions.StudentDeletedException;
import bingol.campus.student.exceptions.StudentNotActiveException;
import bingol.campus.student.exceptions.StudentNotFoundException;
import bingol.campus.student.repository.StudentRepository;
import bingol.campus.student.rules.StudentRules;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BlockRelationManager implements BlockRelationService {
    private final StudentRepository studentRepository;
    private final BlockRelationRepository blockRelationRepository;
    private final BlockRelationConverter blockRelationConverter;
    private final FriendRequestRepository friendRequestRepository;
    private final CommentRepository commentRepository;
    private final LikeRepository likeRepository;
    private final PostRepository postRepository;
    private final StoryRepository storyRepository;
    private final FollowRelationRepository followRelationRepository;
    private final StudentRules studentRules;

    @Override
    public DataResponseMessage<List<BlockUserDTO>> getBlockedUsers(String username, Pageable pageable) throws StudentNotFoundException {
        // Öğrenciyi bul
        Student student = studentRepository.getByUserNumber(username);

        // Engellenmiş kullanıcılarla ilgili BlockRelation nesnelerini al
        Page<BlockRelation> blockRelationsPage = blockRelationRepository.findByBlocker(student, pageable);

        // Engellenmiş kullanıcılara ait DTO'ları almak için her BlockRelation'ı dönüştür
        List<BlockUserDTO> blockUserDTOS = blockRelationsPage.getContent().stream()
                .filter(blockRelation -> blockRelation.getBlocked().getIsActive()) // Yalnızca aktif engellenmiş kullanıcıları al
                .map(blockRelationConverter::toDTO)
                .collect(Collectors.toList());

        // Sayfa bilgisi ve içerik ile döndür
        return new DataResponseMessage<List<BlockUserDTO>>(
                "Engellenmiş aktif kullanıcılar listesi",
                true,
                blockUserDTOS
        );
    }



    @Override
    @Transactional
    public ResponseMessage unblock(String username, Long userId) throws BlockUserNotFoundException, StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);
        BlockRelation blockRelation = student.getBlocked().stream().filter(blockRelation1 -> blockRelation1.getBlocked().getId().equals(userId)).findFirst().orElseThrow(BlockUserNotFoundException::new);
        student.getBlocked().remove(blockRelation);
        studentRepository.save(student);
        blockRelationRepository.delete(blockRelation);
        return new ResponseMessage("engellenen kullanıcı kaldırıldı", true);
    }

    @Override
    public ResponseMessage checkBlockStatus(String username, Long userId) throws StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);
        Optional<BlockRelation> blockRelation = student.getBlocked().stream().filter(blockRelation1 -> blockRelation1.getBlocked().getId().equals(userId)).findFirst();
        if (blockRelation.isEmpty()) {
            return new ResponseMessage("Kullanıcı engellenmemiş", true);
        }
        return new ResponseMessage("Kullanıcı engellenmiş", true);
    }

    @Override
    public DataResponseMessage<LocalDate> getBlockHistory(String username, Long userId) throws BlockUserNotFoundException, StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);
        BlockRelation blockRelation = student.getBlocked().stream().filter(blockRelation1 -> blockRelation1.getBlocked().getId().equals(userId)).findFirst().orElseThrow(BlockUserNotFoundException::new);
        return new DataResponseMessage<>("engellenen tarih", true, blockRelation.getBlockDate());
    }

    @Override
    public DataResponseMessage<BlockUserDTO> getUserDetails(String username, Long userId) throws BlockUserNotFoundException, StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);
        BlockRelation blockRelation = student.getBlocked().stream().filter(blockRelation1 -> blockRelation1.getBlocked().getId().equals(userId)).findFirst().orElseThrow(BlockUserNotFoundException::new);
        BlockUserDTO blockUserDTO = blockRelationConverter.toDTO(blockRelation);
        return new DataResponseMessage<BlockUserDTO>("kullanıcı", true, blockUserDTO);
    }

    @Override
    public DataResponseMessage getBlockCount(String username) throws StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);
        return new DataResponseMessage("engellenen sayısı", true,  student.getBlocked().size());
    }

    @Override
    @Transactional
    public ResponseMessage addWithReason(String username, Long userId) throws AlreadyBlockUserException, StudentNotFoundException, StudentDeletedException, StudentNotActiveException {
        // Öğrenciyi al
        Student blocker = studentRepository.getByUserNumber(username);
        Student blocked = studentRepository.findById(userId)
                .orElseThrow(StudentNotFoundException::new);

        studentRules.baseControl(blocked);
        // Öğrencinin zaten engellenip engellenmediğini kontrol et
        if (isAlreadyBlocked(blocker, blocked)) {
            throw new AlreadyBlockUserException();
        }

        // Yeni blokaj ilişkisini oluştur ve kaydet
        createBlockRelation(blocker, blocked);

        // Takip ve arkadaşlık ilişkilerini temizle
        cleanupRelations(blocker, blocked);
        cleanupRelations(blocked,blocker);

        return new ResponseMessage("Engelleme başarılı ve ilişkiler temizlendi", true);
    }

    private boolean isAlreadyBlocked(Student blocker, Student blocked) {
        return blocker.getBlocked().stream()
                .anyMatch(blockRelation -> blockRelation.getBlocked().equals(blocked));
    }

    private void createBlockRelation(Student blocker, Student blocked) {
        BlockRelation blockRelation = new BlockRelation();
        blockRelation.setBlockDate(LocalDate.now());
        blockRelation.setBlocked(blocked);
        blockRelation.setBlocker(blocker);
        blockRelationRepository.save(blockRelation);

        blocker.getBlocked().add(blockRelation);
    }

    private void cleanupRelations(Student student1, Student student2) {
        // Takip ilişkilerini sil
        followRelationRepository.deleteByFollowerAndFollowed(student1, student2);
        followRelationRepository.deleteByFollowerAndFollowed(student2, student1);

        // Arkadaşlık isteklerini sil
        friendRequestRepository.deleteBySenderAndReceiver(student1, student2);
        friendRequestRepository.deleteBySenderAndReceiver(student2, student1);

        // Gönderi ve Hikayelerdeki beğeni ve yorumları sil
        deleteLikesAndComments(student1, student2);
    }

    private void deleteLikesAndComments(Student student1, Student student2) {
        // Gönderilerdeki beğenileri ve yorumları sil
        List<Post> posts = postRepository.findByStudent(student1); // student1'in gönderilerini al
        for (Post post : posts) {
            // student2'nin bu gönderiye yaptığı beğenileri bul ve sil
            List<Like> likesToRemove = post.getLikes().stream()
                    .filter(like -> like.getStudent().equals(student2))
                    .collect(Collectors.toList());
            post.getLikes().removeAll(likesToRemove);  // Listeden çıkar
            likeRepository.deleteAll(likesToRemove);  // Veritabanından sil

            // student2'nin bu gönderiye yaptığı yorumları bul ve sil
            List<Comment> commentsToRemove = post.getComments().stream()
                    .filter(comment -> comment.getStudent().equals(student2))
                    .collect(Collectors.toList());
            post.getComments().removeAll(commentsToRemove);  // Listeden çıkar
            commentRepository.deleteAll(commentsToRemove);  // Veritabanından sil

            // Güncellenmiş gönderiyi kaydet
            postRepository.save(post);
        }

        // Hikayelerdeki beğenileri ve yorumları sil
        List<Story> stories = storyRepository.findByStudent(student1); // student1'in hikayelerini al
        for (Story story : stories) {
            // student2'nin bu hikayeye yaptığı beğenileri bul ve sil
            List<Like> likesToRemove = story.getLikes().stream()
                    .filter(like -> like.getStudent().equals(student2))
                    .collect(Collectors.toList());
            story.getLikes().removeAll(likesToRemove);  // Listeden çıkar
            likeRepository.deleteAll(likesToRemove);  // Veritabanından sil

            // student2'nin bu hikayeye yaptığı yorumları bul ve sil
            List<Comment> commentsToRemove = story.getComments().stream()
                    .filter(comment -> comment.getStudent().equals(student2))
                    .collect(Collectors.toList());
            story.getComments().removeAll(commentsToRemove);  // Listeden çıkar
            commentRepository.deleteAll(commentsToRemove);  // Veritabanından sil

            // Güncellenmiş hikayeyi kaydet
            storyRepository.save(story);
        }
    }


}
