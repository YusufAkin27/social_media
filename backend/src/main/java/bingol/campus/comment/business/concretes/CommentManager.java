package bingol.campus.comment.business.concretes;

import bingol.campus.comment.business.abstracts.CommentService;
import bingol.campus.comment.core.converter.CommentConverter;
import bingol.campus.comment.core.exception.CommentNotFoundException;
import bingol.campus.comment.core.exception.UnauthorizedCommentException;
import bingol.campus.comment.core.response.CommentDTO;
import bingol.campus.comment.entity.Comment;
import bingol.campus.comment.repository.CommentRepository;
import bingol.campus.followRelation.core.exceptions.BlockingBetweenStudent;
import bingol.campus.notification.NotificationController;
import bingol.campus.notification.SendNotificationRequest;
import bingol.campus.post.core.exceptions.PostNotFoundException;
import bingol.campus.post.core.exceptions.PostNotIsActiveException;
import bingol.campus.post.entity.Post;
import bingol.campus.post.repository.PostRepository;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;
import bingol.campus.story.core.exceptions.NotFollowingException;
import bingol.campus.story.core.exceptions.StoryNotActiveException;
import bingol.campus.story.core.exceptions.StoryNotFoundException;
import bingol.campus.story.core.exceptions.StudentProfilePrivateException;
import bingol.campus.story.entity.Story;
import bingol.campus.story.repository.StoryRepository;
import bingol.campus.student.core.converter.StudentConverter;
import bingol.campus.student.entity.Student;
import bingol.campus.student.exceptions.StudentNotFoundException;
import bingol.campus.student.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CommentManager implements CommentService {
    private final StudentRepository studentRepository;
    private final StoryRepository storyRepository;
    private final PostRepository postRepository;
    private final NotificationController notificationController;
    private final CommentRepository commentRepository;

    @Override
    @Transactional
    public ResponseMessage addCommentToStory(String username, UUID storyId, String content) throws StudentNotFoundException, StoryNotFoundException, BlockingBetweenStudent, NotFollowingException, StoryNotActiveException, StudentProfilePrivateException {
        Student student = studentRepository.getByUserNumber(username); // Öğrenci bilgisi alınıyor
        Story story = storyRepository.findById(storyId).orElseThrow(StoryNotFoundException::new); // Hikaye bilgisi alınıyor

        // Erişim kontrol fonksiyonunu çağırıyoruz
        checkAccessToStory(student, story);

        // Yorum ekleme işlemi burada yapılır (yorum nesnesi oluşturulup hikayeye eklenir)
        Comment comment = new Comment();
        comment.setContent(content);
        comment.setStudent(student);
        comment.setStory(story);
        comment.setPost(null);
        comment.setCreatedAt(LocalDateTime.now());

        // Yorum hikayeye ekleniyor
        story.getComments().add(comment);

        // Veritabanına kaydediliyor
        commentRepository.save(comment);
        storyRepository.save(story);

        if (story.getStudent().getFcmToken() != null) {
            SendNotificationRequest sendNotificationRequest = new SendNotificationRequest();
            sendNotificationRequest.setTitle("Yorum geldi");
            sendNotificationRequest.setFmcToken(story.getStudent().getFcmToken());
            sendNotificationRequest.setMessage(story.getStudent().getUsername() + " kullanıcısı hikayenize yorum yaptı.");

            try {
                notificationController.sendToUser(sendNotificationRequest);
            } catch (Exception e) {
                System.err.println("Bildirim gönderme hatası: " + e.getMessage());
            }
        } else {
            System.out.println("Kabul edilen kullanıcının FCM Token değeri bulunamadı!");
        }

        return new ResponseMessage("Yorum başarıyla eklendi.", true);
    }


    public void checkAccessToStory(Student student, Story story) throws BlockingBetweenStudent, StoryNotActiveException, StudentProfilePrivateException {
        // Hikayenin aktif olup olmadığını kontrol et
        if (!story.getIsActive()) {
            throw new StoryNotActiveException();
        }

        // Hikayeyi paylaştığı öğrenci (student1) bilgisi
        Student student1 = story.getStudent();

        hasAccessToContent(student, student1);
    }

    public void checkAccessToPost(Student student, Post post) throws BlockingBetweenStudent, NotFollowingException, PostNotIsActiveException, StudentProfilePrivateException {
        // Gönderinin aktif olup olmadığını kontrol et
        if (!post.isActive()) {
            throw new PostNotIsActiveException();
        }

        // Gönderiyi paylaştığı öğrenci (student1) bilgisi
        Student student1 = post.getStudent();

        hasAccessToContent(student, student1);
    }

    private void hasAccessToContent(Student student, Student student1) throws BlockingBetweenStudent, StudentProfilePrivateException {

        if (student.equals(student1)) {
            return;
        }
        boolean blocked = student.getBlocked().stream().anyMatch(b -> b.getBlocked().equals(student1)) ||
                student1.getBlocked().stream().anyMatch(b -> b.getBlocked().equals(student));

        if (blocked) {
            throw new BlockingBetweenStudent();
        }

        if (student1.isPrivate()) {
            boolean isFollowing = student.getFollowing().stream()
                    .anyMatch(f -> f.getFollowed().equals(student1));

            if (!isFollowing) {
                throw new StudentProfilePrivateException();
            }

        }
    }

    @Override
    @Transactional
    public ResponseMessage addCommentToPost(String username, UUID postId, String content) throws PostNotFoundException, StudentNotFoundException, PostNotIsActiveException, NotFollowingException, BlockingBetweenStudent, StudentProfilePrivateException {
        Student student = studentRepository.getByUserNumber(username); // Öğrenci bilgisi alınıyor
        Post post = postRepository.findById(postId).orElseThrow(PostNotFoundException::new); // Hikaye bilgisi alınıyor

        // Erişim kontrol fonksiyonunu çağırıyoruz
        checkAccessToPost(student, post);

        // Yorum ekleme işlemi burada yapılır (yorum nesnesi oluşturulup hikayeye eklenir)
        Comment comment = new Comment();
        comment.setContent(content);
        comment.setStudent(student);
        comment.setStory(null);
        comment.setPost(post);
        comment.setCreatedAt(LocalDateTime.now());

        // Yorum hikayeye ekleniyor
        post.getComments().add(comment);

        // Veritabanına kaydediliyor
        commentRepository.save(comment);
        postRepository.save(post);

        if (post.getStudent().getFcmToken() != null) {
            SendNotificationRequest sendNotificationRequest = new SendNotificationRequest();
            sendNotificationRequest.setTitle("Yorum geldi");
            sendNotificationRequest.setFmcToken(post.getStudent().getFcmToken());
            sendNotificationRequest.setMessage(post.getStudent().getUsername() + " kullanıcısı gönderinize yorum yaptı.");

            try {
                notificationController.sendToUser(sendNotificationRequest);
            } catch (Exception e) {
                System.err.println("Bildirim gönderme hatası: " + e.getMessage());
            }
        } else {
            System.out.println("Kabul edilen kullanıcının FCM Token değeri bulunamadı!");
        }
        return new ResponseMessage("Yorum başarıyla eklendi.", true);
    }

    @Override
    @Transactional
    public ResponseMessage deleteComment(String username, UUID commentId) throws CommentNotFoundException, StudentNotFoundException, UnauthorizedCommentException {
        Student student = studentRepository.getByUserNumber(username); // Kullanıcı bilgisi alınıyor
        Comment comment = commentRepository.findById(commentId).orElseThrow(CommentNotFoundException::new); // Yorum bilgisi alınıyor

        if (comment.getStudent().equals(student)) {
            commentRepository.delete(comment);
            return new ResponseMessage("yorum kaldırıldı", true);
        }

        // Yorumun ait olduğu gönderi veya hikaye
        Post post = comment.getPost(); // Gönderi bilgisi
        Story story = comment.getStory(); // Hikaye bilgisi

        // Yorumun ait olduğu gönderiye aitse
        if (post != null) {
            // Kullanıcı, gönderi sahibi ya da yorum yapan kişi mi?
            if (post.getStudent().equals(student) || comment.getStudent().equals(student)) {
                commentRepository.delete(comment); // Yorum siliniyor
                return new ResponseMessage("Yorum başarıyla silindi.", true);
            }
        }
        // Yorum hikayeye aitse
        if (story != null) {
            // Kullanıcı, hikaye sahibi ya da yorum yapan kişi mi?
            if (story.getStudent().equals(student) || comment.getStudent().equals(student)) {
                commentRepository.delete(comment); // Yorum siliniyor
                return new ResponseMessage("Yorum başarıyla silindi.", true);
            }
        }

        // Yorum sahibi ve hikaye/gönderi sahibi dışında kimse silemez
        throw new UnauthorizedCommentException();
    }

    @Override
    public DataResponseMessage<List<CommentDTO>> getUserComments(String username, Pageable pageable) throws StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username); // Kullanıcı bilgisi alınıyor

        // Kullanıcının yazdığı tüm aktif yorumlar (hem hikaye hem de gönderiler için)
        Page<Comment> commentsPage = commentRepository.findByStudent(student, pageable); // Sayfalama ile aktif yorumları alıyoruz

        // Yorumları DTO'ya çevirip döndürüyoruz
        List<CommentDTO> commentDTOs = commentsPage.getContent().stream()
                .map(comment -> {
                    CommentDTO dto = new CommentDTO();
                    dto.setId(comment.getId());
                    dto.setContent(comment.getContent());
                    dto.setUsername(comment.getStudent().getUsername());
                    dto.setCreatedAt(comment.getCreatedAt());
                    dto.setProfilePhoto(comment.getStudent().getProfilePhoto());

                    // Yalnızca aktif gönderi veya hikaye varsa
                    if (comment.getPost() != null ) {
                        dto.setPostId(comment.getPost().getId());  // Eğer yorum gönderiye aitse ve aktifse
                    } else if (comment.getStory() != null ) {
                        dto.setStoryId(comment.getStory().getId());  // Eğer yorum hikayeye aitse ve aktifse
                    }
                    return dto;
                })
                .collect(Collectors.toList());

        return new DataResponseMessage<>("Yorumlar başarıyla getirildi.", true, commentDTOs);
    }


    @Override
    public DataResponseMessage<List<CommentDTO>> getStoryComments(String username, UUID storyId, Pageable pageable)
            throws NotFollowingException, BlockingBetweenStudent, StoryNotActiveException, StudentNotFoundException, StoryNotFoundException, StudentProfilePrivateException {

        // Kullanıcı bilgisi alınıyor
        Student student = studentRepository.getByUserNumber(username);

        // Hikaye bilgisi alınıyor
        Story story = storyRepository.findById(storyId).orElseThrow(StoryNotFoundException::new);

        // Hikayenin erişilebilir olup olmadığını kontrol et
        checkAccessToStory(student, story);

        // Sayfalama ile hikayeye ait yorumları al
        Page<Comment> commentsPage = commentRepository.findByStory(story, pageable);

        // Yorumları DTO'ya çevir
        List<CommentDTO> commentDTOs = commentsPage.getContent().stream()
                .map(comment -> {
                    CommentDTO dto = new CommentDTO();
                    dto.setId(comment.getId());
                    dto.setContent(comment.getContent());
                    dto.setCreatedAt(comment.getCreatedAt());
                    dto.setProfilePhoto(comment.getStudent().getProfilePhoto());
                    dto.setStoryId(comment.getStory().getId());
                    dto.setUsername(comment.getStudent().getUsername());
                    return dto;
                })
                .collect(Collectors.toList());

        return new DataResponseMessage<>("Yorumlar başarıyla getirildi.", true, commentDTOs);
    }


    @Override
    public DataResponseMessage<List<CommentDTO>> getPostComments(String username, UUID postId, Pageable pageable)
            throws StudentNotFoundException, PostNotFoundException, PostNotIsActiveException, NotFollowingException, BlockingBetweenStudent, StudentProfilePrivateException {

        // Kullanıcı bilgisi alınıyor
        Student student = studentRepository.getByUserNumber(username);

        // Gönderi bilgisi alınıyor
        Post post = postRepository.findById(postId).orElseThrow(PostNotFoundException::new);

        // Gönderinin erişilebilir olup olmadığını kontrol et
        checkAccessToPost(student, post);

        // Sayfalama ile gönderiye ait yorumlar alınıyor
        Page<Comment> commentsPage = commentRepository.findByPost(post, pageable);

        // Yorumları DTO'ya çevir
        List<CommentDTO> commentDTOs = commentsPage.getContent().stream()
                .map(comment -> {
                    CommentDTO dto = new CommentDTO();
                    dto.setId(comment.getId());
                    dto.setPostId(comment.getPost().getId());
                    dto.setUsername(comment.getStudent().getUsername());
                    dto.setProfilePhoto(comment.getStudent().getProfilePhoto());
                    dto.setContent(comment.getContent());
                    dto.setCreatedAt(comment.getCreatedAt());
                    return dto;
                })
                .collect(Collectors.toList());

        return new DataResponseMessage<>("Yorumlar başarıyla getirildi.", true, commentDTOs);
    }

    @Override
    public DataResponseMessage<CommentDTO> getCommentDetails(String username, UUID commentId) throws CommentNotFoundException, StudentNotFoundException, UnauthorizedCommentException {
        Student student = studentRepository.getByUserNumber(username); // Kullanıcı bilgisi alınıyor
        Comment comment = commentRepository.findById(commentId).orElseThrow(CommentNotFoundException::new); // Yorum bilgisi alınıyor

        // Yorumun sahibini kontrol et
        if (!comment.getStudent().equals(student)) {
            throw new UnauthorizedCommentException();
        }

        // Yorum detaylarını DTO'ya çevir
        CommentDTO commentDTO = new CommentDTO();
        commentDTO.setId(comment.getId());
        commentDTO.setContent(comment.getContent());
        commentDTO.setCreatedAt(comment.getCreatedAt());

        return new DataResponseMessage<>("Yorum detayları başarıyla getirildi.", true, commentDTO);
    }


    @Override
    public DataResponseMessage<List<CommentDTO>> searchUserInStoryComments(String username, UUID storyId, String username1) throws UnauthorizedCommentException, StudentNotFoundException, StoryNotFoundException {
        Student student = studentRepository.getByUserNumber(username); // Kullanıcı bilgisi alınıyor
        Story story = storyRepository.findById(storyId).orElseThrow(StoryNotFoundException::new); // Hikaye bilgisi alınıyor


        // Yalnızca hikaye sahibi arama yapabilir
        if (!story.getStudent().equals(student)) {
            throw new UnauthorizedCommentException();
        }

        // Belirli bir kullanıcıyı aramak için yorumları filtrele
        List<CommentDTO> commentDTOs = story.getComments().stream()
                .filter(comment -> comment.getStudent().getUserNumber().equals(username1)) // Yalnızca username1'e ait yorumları al
                .map(comment -> {
                    CommentDTO dto = new CommentDTO();
                    dto.setId(comment.getId());
                    dto.setContent(comment.getContent());
                    dto.setCreatedAt(comment.getCreatedAt());
                    return dto;
                })
                .collect(Collectors.toList());


        return new DataResponseMessage<>("Yorumlar başarıyla arandı.", true, commentDTOs);
    }

    @Override
    public DataResponseMessage<List<CommentDTO>> searchUserInPostComments(String username, UUID postId, String username1) throws StudentNotFoundException, PostNotFoundException, UnauthorizedCommentException {
        Student student = studentRepository.getByUserNumber(username); // Kullanıcı bilgisi alınıyor
        Post post = postRepository.findById(postId).orElseThrow(PostNotFoundException::new); // Gönderi bilgisi alınıyor


        // Yalnızca gönderi sahibi arama yapabilir
        if (!post.getStudent().equals(student)) {
            throw new UnauthorizedCommentException();
        }

        // Belirli bir kullanıcıyı aramak için yorumları filtrele
        List<CommentDTO> commentDTOs = post.getComments().stream()
                .filter(comment -> comment.getStudent().getUserNumber().equals(username1)) // Yalnızca username1'e ait yorumları al
                .map(comment -> {
                    CommentDTO dto = new CommentDTO();
                    dto.setId(comment.getId());
                    dto.setContent(comment.getContent());
                    dto.setCreatedAt(comment.getCreatedAt());
                    return dto;
                })
                .collect(Collectors.toList());

        return new DataResponseMessage<>("Yorumlar başarıyla arandı.", true, commentDTOs);
    }

}
