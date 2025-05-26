package bingol.campus.post.business.concretes;

import bingol.campus.blockRelation.entity.BlockRelation;
import bingol.campus.comment.core.converter.CommentConverter;
import bingol.campus.comment.entity.Comment;
import bingol.campus.comment.repository.CommentRepository;
import bingol.campus.config.MediaUploadService;
import bingol.campus.followRelation.entity.FollowRelation;
import bingol.campus.like.core.converter.LikeConverter;
import bingol.campus.like.entity.Like;
import bingol.campus.like.repository.LikeRepository;
import bingol.campus.notification.NotificationController;
import bingol.campus.notification.SendBulkNotificationRequest;
import bingol.campus.notification.SendNotificationRequest;
import bingol.campus.post.business.abstracts.PostService;
import bingol.campus.post.core.converter.PostConverter;
import bingol.campus.post.core.exceptions.*;
import bingol.campus.post.core.response.CommentDetailsDTO;
import bingol.campus.post.core.response.LikeDetailsDTO;
import bingol.campus.post.core.response.PostDTO;
import bingol.campus.post.entity.Post;
import bingol.campus.post.repository.PostRepository;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;
import bingol.campus.security.exception.UserNotFoundException;
import bingol.campus.story.core.exceptions.OwnerStoryException;
import bingol.campus.story.core.exceptions.StoryNotFoundException;
import bingol.campus.story.entity.Story;
import bingol.campus.story.repository.StoryRepository;
import bingol.campus.student.entity.Student;
import bingol.campus.student.exceptions.*;
import bingol.campus.student.repository.StudentRepository;
import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.MediaTypeEditor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PostManager implements PostService {
    private final PostConverter postConverter;
    private final PostRepository postRepository;
    private final StudentRepository studentRepository;
    private final CommentConverter commentConverter;
    private final StoryRepository storyRepository;
    private final LikeConverter likeConverter;
    private final LikeRepository likeRepository;
    private final NotificationController notificationController;
    private final CommentRepository commentRepository;
    private final MediaUploadService mediaUploadService;

    @Override
    @Transactional
    public ResponseMessage add(String username, String description, String location, List<String> tagAPerson, MultipartFile[] photos) throws InvalidPostRequestException, StudentNotFoundException, UnauthorizedTaggingException, BlockedUserTaggedException, IOException, OnlyPhotosAndVideosException, PhotoSizeLargerException, VideoSizeLargerException, FileFormatCouldNotException {
        Student student = studentRepository.getByUserNumber(username);

        if (photos == null || photos.length == 0) {
            return new ResponseMessage("Fotoğraf boş olamaz.", false);
        }

        if (tagAPerson != null && !tagAPerson.isEmpty()) {
            validateTaggedPersons(tagAPerson, student);
        }

        Post post = Post.builder()
                .description(description)
                .location(location)
                .isActive(true)
                .isDelete(false)
                .photos(new ArrayList<>()) // Liste başlatıldı
                .createdAt(LocalDateTime.now())
                .taggedPersons(new ArrayList<>()) // Liste başlatıldı
                .build();
        post.setStudent(student);

        List<CompletableFuture<String>> futures = Arrays.stream(photos)
                .map(file -> {
                    try {
                        return mediaUploadService.uploadAndOptimizeMedia(file);
                    } catch (IOException | VideoSizeLargerException | OnlyPhotosAndVideosException |
                             PhotoSizeLargerException | FileFormatCouldNotException e) {
                        throw new RuntimeException(e);
                    }
                })
                .toList();

        CompletableFuture.allOf(futures.toArray(new CompletableFuture[0])).join();

        List<String> uploadedUrls = futures.stream()
                .map(CompletableFuture::join)
                .collect(Collectors.toList());

        post.setPhotos(uploadedUrls);

        // **Etiketlenen kullanıcıları ekle**
        if (tagAPerson != null && !tagAPerson.isEmpty()) {
            for (String taggedUsername : tagAPerson) {
                Student taggedStudent = studentRepository.getByUserNumber(taggedUsername);
                if (taggedStudent != null) {
                    post.getTaggedPersons().add(taggedStudent);
                } else {
                    throw new StudentNotFoundException();
                }
            }
        }

        student.getPost().add(post);
        postRepository.save(post); // **Gönderiyi kaydet**

        // **Takipçilere bildirim gönder**
        List<String> fmcTokens = student.getFollowers().stream()
                .map(FollowRelation::getFollowed)
                .filter(f -> f.getFcmToken() != null && f.getIsActive())
                .map(Student::getFcmToken)
                .toList();

        if (!fmcTokens.isEmpty()) {
            SendBulkNotificationRequest sendBulkNotificationRequest = new SendBulkNotificationRequest();
            sendBulkNotificationRequest.setTitle("Yeni Gönderi");
            sendBulkNotificationRequest.setMessage(student.getUsername() + " kullanıcısı yeni gönderi paylaştı.");
            sendBulkNotificationRequest.setFmcTokens(fmcTokens);

            try {
                notificationController.sendToUsers(sendBulkNotificationRequest);
            } catch (Exception e) {
                System.err.println("Bildirim gönderme hatası: " + e.getMessage());
            }
        } else {
            System.out.println("Takipçiler arasında bildirim gönderilecek FCM token'ı bulunamadı.");
        }

        return new ResponseMessage("Gönderi başarıyla paylaşıldı.", true);
    }

    @Override
    @Transactional
    public ResponseMessage update(String username, UUID postId, String description, String location, List<String> tagAPerson, MultipartFile[] photos) throws StudentNotFoundException, PostNotFoundException, PostNotFoundForUserException, IOException, UnauthorizedTaggingException, BlockedUserTaggedException, OnlyPhotosAndVideosException, PhotoSizeLargerException, VideoSizeLargerException, FileFormatCouldNotException {
        // Kullanıcıyı al
        Student student = studentRepository.getByUserNumber(username);
        Post post = postRepository.findById(postId)
                .orElseThrow(PostNotFoundException::new);

        // Gönderi sahibinin doğrulanması
        if (!post.getStudent().equals(student)) {
            throw new PostNotFoundForUserException();
        }

        // Açıklama güncellemesi
        if (description != null) {
            post.setDescription(description);
        }

        // Konum güncellemesi
        if (location != null) {
            post.setLocation(location);
        }

        // Fotoğraflar güncellemesi
        if (photos != null && photos.length > 0) {
            List<String> updatedPhotos = new ArrayList<>();

            for (MultipartFile photo : photos) {
                String uploadedPhotoUrl = mediaUploadService.uploadAndOptimizeMedia(photo).join();
                post.getPhotos().add(uploadedPhotoUrl);

            }

            post.setPhotos(updatedPhotos);
        }

        if (tagAPerson != null && !tagAPerson.isEmpty()) {
            validateTaggedPersons(tagAPerson, student);

            List<Student> updatedTaggedPersons = new ArrayList<>();
            for (String taggedUsername : tagAPerson) {
                Student taggedStudent = studentRepository.getByUserNumber(taggedUsername);
                if (taggedStudent != null) {
                    updatedTaggedPersons.add(taggedStudent);
                } else {
                    throw new StudentNotFoundException();
                }
            }

            post.setTaggedPersons(updatedTaggedPersons);
        }

        postRepository.save(post);

        return new ResponseMessage("Gönderi başarıyla güncellendi.", true);
    }


    private void validateTaggedPersons(List<String> taggedUsernames, Student student) throws StudentNotFoundException, BlockedUserTaggedException, UnauthorizedTaggingException {
        // Engellenen kullanıcıları listele
        Set<Student> blockedUsers = student.getBlocked().stream()
                .map(BlockRelation::getBlocked)
                .collect(Collectors.toSet());  // HashSet, O(1) zamanında arama sağlar

        // Geçerli kullanıcıları (takipçiler ve takip ettikleri) listele
        Set<Student> validUsers = new HashSet<>(student.getFollowing().stream()
                .map(FollowRelation::getFollowed)
                .collect(Collectors.toList()));
        validUsers.addAll(student.getFollowers().stream()
                .map(FollowRelation::getFollower)
                .toList());

        // Her taglenen kullanıcıyı kontrol et
        for (String taggedUsername : taggedUsernames) {
            Student taggedUser = studentRepository.getByUserNumber(taggedUsername);

            // Eğer tag edilen kullanıcı bulunamazsa, StudentNotFoundException fırlatılabilir
            if (taggedUser == null) {
                throw new StudentNotFoundException();
            }

            // 1. Engellenen kullanıcılar listesinde olup olmadığını kontrol et
            if (blockedUsers.contains(taggedUser)) {
                throw new BlockedUserTaggedException(taggedUsername);
            }

            // 2. Geçerli kullanıcılar listesinde olup olmadığını kontrol et
            if (!validUsers.contains(taggedUser)) {
                throw new UnauthorizedTaggingException(taggedUsername);
            }
        }
    }


    @Override
    @Transactional
    public ResponseMessage delete(String username, UUID postId)
            throws PostNotFoundForUserException, UserNotFoundException,
            PostAlreadyDeleteException, PostAlreadyNotActiveException,
            StudentNotFoundException {

        Student student = studentRepository.getByUserNumber(username);

        Post post = postRepository.findById(postId)
                .orElseThrow(PostNotFoundForUserException::new);

        if (!post.getStudent().equals(student)) {
            throw new PostNotFoundForUserException();
        }

        if (Boolean.TRUE.equals(post.isDelete())) {
            throw new PostAlreadyDeleteException();
        }

        if (!post.isActive()) {
            throw new PostAlreadyNotActiveException();
        }

        if (student.getArchivedPosts() == null) {
            student.setArchivedPosts(new ArrayList<>());
        }

        student.getArchivedPosts().add(post);
        student.getPost().remove(post);

        post.setDelete(true);
        post.setActive(false);

        postRepository.save(post);
        studentRepository.save(student);

        return new ResponseMessage("Gönderi başarıyla arşive alındı.", true);
    }


    @Override
    public DataResponseMessage<PostDTO> getDetails(String username, UUID postId) throws StudentNotFoundException, PostNotFoundException, PostAccessDeniedWithBlockerException, PostAccessDeniedWithPrivateException {
        // Kullanıcıyı ve gönderiyi al
        Student student = studentRepository.getByUserNumber(username); // İstek yapan kullanıcı
        Post post = postRepository.findById(postId)
                .orElseThrow(PostNotFoundException::new); // Gönderiyi doğrula
        Student postOwner = post.getStudent(); // Gönderi sahibini al

        // 1. Engelleme kontrolü

        isBlockedByPostOwner(student, postOwner);
        // 2. Gizlilik ve takip kontrolü
        isPrivatePostOwner(student, postOwner);

        // 3. Gönderi detaylarını dönüştür ve döndür
        PostDTO postDTO = postConverter.toDto(post); // Gönderiyi DTO'ya dönüştür
        return new DataResponseMessage<>("Gönderi detayları başarıyla getirildi.", true, postDTO);
    }

    public boolean isBlockedByPostOwner(Student student, Student postOwner) throws PostAccessDeniedWithBlockerException {
        boolean isBlockedByPostOwner = postOwner.getBlocked().stream()
                .anyMatch(blockRelation -> blockRelation.getBlocked().equals(student));
        boolean isBlockedByRequester = student.getBlocked().stream()
                .anyMatch(blockRelation -> blockRelation.getBlocked().equals(postOwner));
        if (isBlockedByPostOwner || isBlockedByRequester) {
            throw new PostAccessDeniedWithBlockerException();
        }
        return true;
    }

    public boolean isPrivatePostOwner(Student student, Student postOwner) throws PostAccessDeniedWithPrivateException {
        if (postOwner.isPrivate()) {
            boolean isFollowing = postOwner.getFollowers().stream()
                    .anyMatch(followRelation -> followRelation.getFollower().equals(student));
            if (!isFollowing) {
                throw new PostAccessDeniedWithPrivateException();
            }
        }
        return true;
    }

    public boolean isAccessPost(Student student, Student postOwner) throws PostAccessDeniedWithBlockerException, PostAccessDeniedWithPrivateException {
        isBlockedByPostOwner(student, postOwner);
        isBlockedByPostOwner(postOwner, student);
        isPrivatePostOwner(student, postOwner);
        return true;
    }

    @Override
    public DataResponseMessage<List<PostDTO>> getMyPosts(String username, Pageable pageable) throws StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);

        Page<Post> postsPage = postRepository.findByStudentAndIsActive(student, true, pageable);

        List<PostDTO> postDTOS = postsPage.getContent().stream()
                .map(postConverter::toDto)
                .collect(Collectors.toList());

        return new DataResponseMessage<>("Başarılı", true, postDTOS);
    }


    @Override
    public DataResponseMessage<List<PostDTO>> getUserPosts(String username, String username1, Pageable pageable)
            throws PostAccessDeniedWithBlockerException, PostAccessDeniedWithPrivateException, StudentNotFoundException {

        Student student = studentRepository.getByUserNumber(username);
        Student ownerPost = studentRepository.getByUserNumber(username1);

        if (student.equals(ownerPost)) {
            return getMyPosts(student.getUsername(), pageable);
        }

        isBlockedByPostOwner(student, ownerPost);
        isBlockedByPostOwner(ownerPost, student);
        isPrivatePostOwner(student, ownerPost);

        Page<Post> postsPage = postRepository.findByStudentAndIsActive(ownerPost, true, pageable);

        // Sayfa içeriğini DTO'ya dönüştür
        List<PostDTO> postDTOS = postsPage.getContent().stream()
                .map(postConverter::toDto)
                .collect(Collectors.toList());

        // Sayfa bilgisi ve içerik ile döndür
        return new DataResponseMessage<>("Gönderiler başarıyla alındı.", true, postDTOS);
    }

    @Override
    public ResponseMessage getLikeCount(String username, UUID postId) throws StudentNotFoundException, PostNotFoundException, PostAccessDeniedWithBlockerException, PostAccessDeniedWithPrivateException {
        Student student = studentRepository.getByUserNumber(username);
        Post post = postRepository.findById(postId)
                .orElseThrow(PostNotFoundException::new); // Gönderiyi doğrula
        Student postOwner = post.getStudent(); // Gönderi sahibini al        return null;

        isBlockedByPostOwner(student, postOwner);
        isPrivatePostOwner(student, postOwner);

        return new ResponseMessage("" + post.getLikes().size(), true);

    }

    @Override
    public ResponseMessage getCommentCount(String username, UUID postId) throws StudentNotFoundException, PostNotFoundException, PostAccessDeniedWithBlockerException, PostAccessDeniedWithPrivateException {
        Student student = studentRepository.getByUserNumber(username);
        Post post = postRepository.findById(postId)
                .orElseThrow(PostNotFoundException::new); // Gönderiyi doğrula
        Student postOwner = post.getStudent(); // Gönderi sahibini al        return null;

        isBlockedByPostOwner(student, postOwner);
        isPrivatePostOwner(student, postOwner);

        return new ResponseMessage("" + post.getComments().size(), true);
    }

    @Override
    public DataResponseMessage<List<LikeDetailsDTO>> getLikeDetails(
            String username, UUID postId, Pageable pageable)
            throws StudentNotFoundException, PostNotFoundException, PostAccessDeniedWithPrivateException, PostAccessDeniedWithBlockerException {

        Student student = studentRepository.getByUserNumber(username);
        Post post = postRepository.findById(postId).orElseThrow(PostNotFoundException::new);
        Student postOwner = post.getStudent();

        isBlockedByPostOwner(student, postOwner);
        isBlockedByPostOwner(postOwner, student);
        isPrivatePostOwner(student, postOwner);

        Page<Like> likePage = likeRepository.findByPost(post, pageable);

        List<LikeDetailsDTO> likeDetailsDTOS = likePage.getContent().stream()
                .filter(like -> like.getStudent().getIsActive())
                .map(likeConverter::toDetails)
                .collect(Collectors.toList());

        return new DataResponseMessage<>("Beğeni detayları başarıyla alındı.", true, likeDetailsDTOS);
    }

    @Override
    public DataResponseMessage<List<CommentDetailsDTO>> getCommentDetails(String username, UUID postId, Pageable pageable) throws StudentNotFoundException, PostNotFoundException, PostAccessDeniedWithBlockerException, PostAccessDeniedWithPrivateException {
        Student student = studentRepository.getByUserNumber(username);
        Post post = postRepository.findById(postId).orElseThrow(PostNotFoundException::new);
        Student postOwner = post.getStudent();

        isBlockedByPostOwner(student, postOwner);
        isBlockedByPostOwner(postOwner, student);
        isPrivatePostOwner(student, postOwner);

        Page<Comment> commentPage = commentRepository.findByPost(post, pageable);

        List<CommentDetailsDTO> commentDetailsDTOS = commentPage.getContent().stream()
                .filter(comment -> comment.getStudent().getIsActive())
                .map(commentConverter::toDetails)
                .collect(Collectors.toList());

        return new DataResponseMessage<>("Yorum detayları başarıyla alındı.", true, commentDetailsDTOS);
    }

    @Override
    public DataResponseMessage<List<LikeDetailsDTO>> getStoryLikeDetails(String username, UUID storyId, Pageable pageRequest) throws StudentNotFoundException, OwnerStoryException, StoryNotFoundException, PostAccessDeniedWithPrivateException, PostAccessDeniedWithBlockerException {
        Student student = studentRepository.getByUserNumber(username);
        Story story = storyRepository.findById(storyId).orElseThrow(StoryNotFoundException::new);
        Student student1 = story.getStudent();

        isBlockedByPostOwner(student, student1);
        isBlockedByPostOwner(student1, student);
        isPrivatePostOwner(student, student1);
        Page<Like> likes = likeRepository.findByStory(story, pageRequest);
        List<LikeDetailsDTO> likeDetailsDTOS = likes.stream().filter(like -> like.getStudent().getIsActive()).map(likeConverter::toDetails).toList();
        return new DataResponseMessage<>("hikaye beğenileri", true, likeDetailsDTOS);
    }

    @Override
    public DataResponseMessage<List<CommentDetailsDTO>> getStoryCommentDetails(String username, UUID storyId, Pageable pageRequest) throws StudentNotFoundException, StoryNotFoundException, PostAccessDeniedWithBlockerException, PostAccessDeniedWithPrivateException {
        Student student = studentRepository.getByUserNumber(username);
        Story story = storyRepository.findById(storyId).orElseThrow(StoryNotFoundException::new);
        Student student1 = story.getStudent();

        isBlockedByPostOwner(student, student1);
        isBlockedByPostOwner(student1, student);
        isPrivatePostOwner(student, student1);
        Page<Comment> comments = commentRepository.findByStory(story, pageRequest);
        List<CommentDetailsDTO> commentDetailsDTOS = comments.stream().filter(c -> c.getStudent().getIsActive()).map(commentConverter::toDetails).toList();
        return new DataResponseMessage<>("hikaye yorumları ", true, commentDetailsDTOS);
    }

    @Override
    public DataResponseMessage<List<PostDTO>> archivedPosts(String username) throws StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);
        List<PostDTO> postDTOS = student.getArchivedPosts().stream().map(postConverter::toDto).toList();
        return new DataResponseMessage<>("arşiv", true, postDTOS);
    }

    @Override
    @Transactional
    public ResponseMessage deleteArchived(String username, UUID postId) throws StudentNotFoundException, PostNotFoundException, ArchivedNotFoundPost {
        Student student = studentRepository.getByUserNumber(username);
        Post post = postRepository.findById(postId).orElseThrow(PostNotFoundException::new);
        student.getArchivedPosts().stream().filter(p -> p.equals(post)).findFirst().orElseThrow(ArchivedNotFoundPost::new);
        student.getArchivedPosts().remove(post);
        studentRepository.save(student);
        return new ResponseMessage("gönderi kaldırıldı", true);
    }

    @Override
    public DataResponseMessage<List<PostDTO>> recorded(String username) throws StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);
        List<PostDTO> postDTOS = student.getRecorded().stream().filter(Post::isActive).map(postConverter::toDto).toList();
        return new DataResponseMessage<>("gönderiler", true, postDTOS);
    }

    @Override
    public DataResponseMessage<List<PostDTO>> getPopularity(String username) throws StudentNotFoundException {
        List<PostDTO> postDTOS = postRepository.findAll().stream()
                .sorted(Comparator.comparingLong(Post::getPopularityScore))
                .map(postConverter::toDto)
                .collect(Collectors.toList());
        return new DataResponseMessage("En popüler gönderiler başarıyla getirildi.", true, postDTOS);
    }

    @Override
    public boolean isRecorded(String username, UUID postId) throws StudentNotFoundException {

        Student student = studentRepository.getByUserNumber(username);
        return student.getRecorded().stream().anyMatch(p -> p.getId().equals(postId));
    }

    @Override
    public ResponseMessage deleteRecorded(UserDetails userDetails, UUID postId) throws StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(userDetails.getUsername());
        student.getRecorded().removeIf(p -> p.getId().equals(postId));
        studentRepository.save(student);
        return new ResponseMessage("kaydedilenlerden kaldırıldı", true);
    }

    @Override
    public ResponseMessage addRecorded(UserDetails userDetails, UUID postId) throws StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(userDetails.getUsername());
        Optional<Post> post = postRepository.findById(postId);
        if (post.isPresent()) {
            student.getRecorded().add(post.get());
            studentRepository.save(student);
            return new ResponseMessage("kaydedilenler eklendi", true);
        } else {
            return new ResponseMessage("Gönderi bulunmadı", false);
        }
    }


}
